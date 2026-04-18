#!/bin/bash

# Context Manager 定时任务配置脚本

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MAIN_SCRIPT="$SCRIPT_DIR/context-manager.sh"
CONFIG_DIR="$HOME/.agents/skills/context-manager"
LOG_FILE="$CONFIG_DIR/cron-setup.log"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
  local level="$1"
  local message="$2"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  case "$level" in
    "INFO") color="$BLUE" ;;
    "SUCCESS") color="$GREEN" ;;
    "WARNING") color="$YELLOW" ;;
    "ERROR") color="$RED" ;;
    *) color="$NC" ;;
  esac
  
  echo -e "${color}[$timestamp] [$level] $message${NC}"
  echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# 检查依赖
check_dependencies() {
  log "INFO" "检查依赖..."
  
  # 检查 openclaw
  if ! command -v openclaw &>/dev/null; then
    log "ERROR" "openclaw 命令未找到"
    return 1
  fi
  
  # 检查 python3
  if ! command -v python3 &>/dev/null; then
    log "ERROR" "python3 未找到"
    return 1
  fi
  
  # 检查 bc
  if ! command -v bc &>/dev/null; then
    log "ERROR" "bc 命令未找到"
    return 1
  fi
  
  log "SUCCESS" "所有依赖检查通过"
  return 0
}

# 配置 OpenClaw cron 任务
setup_openclaw_cron() {
  local interval_minutes="${1:-30}"
  
  log "INFO" "配置 OpenClaw cron 任务 (每 ${interval_minutes} 分钟)"
  
  # 创建 cron 任务配置
  local cron_expr="*/${interval_minutes} * * * *"
  
  # 使用 OpenClaw cron 系统创建任务
  if openclaw cron list &>/dev/null; then
    log "INFO" "OpenClaw cron 系统可用"
    
    # 检查是否已存在任务
    local existing_jobs=$(openclaw cron list --json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for job in data.get('jobs', []):
        if job.get('name', '').startswith('context-manager'):
            print(job.get('id', ''))
            break
except:
    pass
" 2>/dev/null)
    
    if [ -n "$existing_jobs" ]; then
      log "WARNING" "已存在 context-manager 任务，先删除"
      openclaw cron remove "$existing_jobs" 2>/dev/null || true
    fi
    
    # 创建新任务
    local job_config=$(cat <<EOF
{
  "name": "context-manager-auto-check",
  "schedule": {
    "kind": "every",
    "everyMs": $(($interval_minutes * 60 * 1000))
  },
  "sessionTarget": "isolated",
  "payload": {
    "kind": "agentTurn",
    "message": "运行 context-manager 自动检查: $MAIN_SCRIPT auto"
  },
  "delivery": {
    "mode": "none"
  },
  "enabled": true
}
EOF
    )
    
    # 临时文件存储配置
    local temp_config=$(mktemp)
    echo "$job_config" > "$temp_config"
    
    # 添加任务
    if openclaw cron add --json "$temp_config" 2>/dev/null; then
      log "SUCCESS" "OpenClaw cron 任务创建成功"
      rm -f "$temp_config"
      return 0
    else
      log "ERROR" "OpenClaw cron 任务创建失败"
      rm -f "$temp_config"
      return 1
    fi
    
  else
    log "WARNING" "OpenClaw cron 系统不可用，使用系统 crontab"
    return 2
  fi
}

# 配置系统 crontab
setup_system_crontab() {
  local interval_minutes="${1:-30}"
  
  log "INFO" "配置系统 crontab (每 ${interval_minutes} 分钟)"
  
  # 创建 crontab 条目
  local cron_line="*/${interval_minutes} * * * * cd '$SCRIPT_DIR' && '$MAIN_SCRIPT' auto >> '$CONFIG_DIR/cron-execution.log' 2>&1"
  
  # 获取当前 crontab
  local current_crontab=$(crontab -l 2>/dev/null || echo "")
  
  # 移除已有的 context-manager 条目
  local new_crontab=$(echo "$current_crontab" | grep -v "context-manager" | grep -v "$MAIN_SCRIPT")
  
  # 添加新条目
  new_crontab=$(echo -e "$new_crontab\n# Context Manager - Auto check\n$cron_line")
  
  # 更新 crontab
  echo "$new_crontab" | crontab -
  
  if [ $? -eq 0 ]; then
    log "SUCCESS" "系统 crontab 配置成功"
    
    # 显示配置
    log "INFO" "当前 crontab 配置:"
    crontab -l | grep -A2 -B2 "context-manager\|$MAIN_SCRIPT"
    return 0
  else
    log "ERROR" "系统 crontab 配置失败"
    return 1
  fi
}

# 测试配置
test_configuration() {
  log "INFO" "测试配置..."
  
  # 测试脚本执行
  if ! "$MAIN_SCRIPT" check >/dev/null 2>&1; then
    log "ERROR" "脚本执行测试失败"
    return 1
  fi
  
  # 测试自动检查
  local test_output="$("$MAIN_SCRIPT" auto 2>&1)"
  if echo "$test_output" | grep -q "ERROR\|失败"; then
    log "ERROR" "自动检查测试失败"
    echo "$test_output" | tail -5
    return 1
  fi
  
  log "SUCCESS" "配置测试通过"
  return 0
}

# 显示状态
show_status() {
  log "INFO" "Context Manager 状态检查"
  echo ""
  
  # 脚本状态
  echo "📋 Script Status:"
  if [ -x "$MAIN_SCRIPT" ]; then
    echo "  ✅ $MAIN_SCRIPT (可执行)"
  else
    echo "  ❌ $MAIN_SCRIPT (不可执行)"
  fi
  
  # 配置状态
  echo ""
  echo "⚙️ Configuration:"
  if [ -f "$CONFIG_DIR/config.json" ]; then
    echo "  ✅ $CONFIG_DIR/config.json"
    
    # 显示配置摘要
    local interval=$(python3 -c "
import json
try:
    with open('$CONFIG_DIR/config.json', 'r') as f:
        config = json.load(f)
    schedule = config.get('schedule', {})
    print(f\"Interval: {schedule.get('interval_minutes', 30)} minutes\")
except:
    print('Error reading config')
" 2>/dev/null)
    echo "  📅 $interval"
  else
    echo "  ❌ 配置文件不存在"
  fi
  
  # Cron 状态
  echo ""
  echo "⏰ Scheduled Tasks:"
  
  # 检查 OpenClaw cron
  if openclaw cron list &>/dev/null 2>&1; then
    local openclaw_jobs=$(openclaw cron list --json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    count = 0
    for job in data.get('jobs', []):
        if 'context-manager' in job.get('name', ''):
            count += 1
            print(f\"  ✅ OpenClaw Cron: {job.get('name')}\")
    if count == 0:
        print('  ⚠️  No OpenClaw cron jobs found')
except:
    print('  ❌ OpenClaw cron check failed')
")
    echo "$openclaw_jobs"
  else
    echo "  ⚠️  OpenClaw cron 不可用"
  fi
  
  # 检查系统 crontab
  local system_cron=$(crontab -l 2>/dev/null | grep -c "context-manager\|$MAIN_SCRIPT")
  if [ "$system_cron" -gt 0 ]; then
    echo "  ✅ System Crontab: $system_cron job(s)"
    crontab -l 2>/dev/null | grep -B1 -A1 "context-manager\|$MAIN_SCRIPT" | sed 's/^/    /'
  else
    echo "  ⚠️  No system crontab jobs"
  fi
  
  # 日志状态
  echo ""
  echo "📊 Logs:"
  if [ -f "$LOG_FILE" ]; then
    local log_size=$(du -h "$LOG_FILE" | cut -f1)
    local log_lines=$(wc -l < "$LOG_FILE" 2>/dev/null || echo "0")
    echo "  📝 $LOG_FILE ($log_size, $log_lines lines)"
  else
    echo "  📝 No log file yet"
  fi
  
  if [ -f "$CONFIG_DIR/cron-execution.log" ]; then
    local exec_log_size=$(du -h "$CONFIG_DIR/cron-execution.log" | cut -f1)
    echo "  ⚡ Cron execution log: $exec_log_size"
  fi
}

# 显示帮助
show_help() {
  cat <<EOF
${BLUE}Context Manager Cron Setup${NC}

Usage: $0 <command> [interval_minutes]

Commands:
  setup [minutes]     配置定时任务 (默认30分钟)
  test                测试配置
  status              显示当前状态
  remove              移除所有定时任务
  help                显示此帮助

Examples:
  $0 setup            配置每30分钟检查
  $0 setup 60         配置每小时检查
  $0 test             测试配置
  $0 status           显示状态
  $0 remove           移除定时任务

说明:
  1. 优先使用 OpenClaw cron 系统
  2. 如果不可用，则使用系统 crontab
  3. 定时执行 context-manager auto 命令
  4. 检查上下文负载并在需要时压缩

配置文件: $CONFIG_DIR/config.json
日志文件: $LOG_FILE
EOF
}

# 移除定时任务
remove_tasks() {
  log "INFO" "移除所有定时任务..."
  
  # 移除 OpenClaw cron 任务
  if openclaw cron list &>/dev/null; then
    local job_ids=$(openclaw cron list --json 2>/dev/null | python3 -c "
import json, sys
try:
    data = json.load(sys.stdin)
    for job in data.get('jobs', []):
        if 'context-manager' in job.get('name', ''):
            print(job.get('id', ''))
except:
    pass
" 2>/dev/null)
    
    for job_id in $job_ids; do
      if [ -n "$job_id" ]; then
        openclaw cron remove "$job_id" 2>/dev/null && \
          log "INFO" "移除 OpenClaw cron 任务: $job_id"
      fi
    done
  fi
  
  # 移除系统 crontab 条目
  local current_crontab=$(crontab -l 2>/dev/null || echo "")
  local new_crontab=$(echo "$current_crontab" | grep -v "context-manager" | grep -v "$MAIN_SCRIPT")
  
  if [ "$current_crontab" != "$new_crontab" ]; then
    echo "$new_crontab" | crontab -
    log "SUCCESS" "系统 crontab 条目已移除"
  else
    log "INFO" "系统 crontab 中未找到相关条目"
  fi
  
  log "SUCCESS" "所有定时任务已移除"
}

# 主函数
main() {
  # 创建配置目录
  mkdir -p "$CONFIG_DIR"
  
  local command="${1:-help}"
  local interval="${2:-30}"
  
  case "$command" in
    setup)
      # 检查依赖
      if ! check_dependencies; then
        log "ERROR" "依赖检查失败，请先安装所需工具"
        return 1
      fi
      
      # 尝试 OpenClaw cron
      if setup_openclaw_cron "$interval"; then
        log "SUCCESS" "使用 OpenClaw cron 系统配置成功"
      elif [ $? -eq 2 ]; then
        # 回退到系统 crontab
        log "INFO" "回退到系统 crontab"
        setup_system_crontab "$interval"
      fi
      
      # 测试配置
      test_configuration
      ;;
      
    test)
      check_dependencies
      test_configuration
      ;;
      
    status)
      show_status
      ;;
      
    remove)
      remove_tasks
      ;;
      
    help|--help|-h)
      show_help
      ;;
      
    *)
      log "ERROR" "未知命令: $command"
      echo ""
      show_help
      return 1
      ;;
  esac
}

# 运行主函数
main "$@"