#!/bin/bash

# 简单的上下文检查脚本

echo "🔍 检查 OpenClaw 上下文状态..."

# 获取当前状态
STATUS=$(openclaw session_status 2>/dev/null)

if [ $? -ne 0 ]; then
    echo "❌ 无法获取 OpenClaw 状态"
    exit 1
fi

# 提取关键信息
CONTEXT_INFO=$(echo "$STATUS" | grep "Context:")
TOKEN_INFO=$(echo "$STATUS" | grep "Tokens:")
CACHE_INFO=$(echo "$STATUS" | grep "Cache:")
COST_INFO=$(echo "$STATUS" | grep "Cost:")
COMPACTIONS=$(echo "$STATUS" | grep "Compactions:")

echo ""
echo "📊 上下文状态报告"
echo "=================="

# 显示信息
if [ -n "$CONTEXT_INFO" ]; then
    echo "📈 上下文使用: $CONTEXT_INFO"
    
    # 计算使用率
    USAGE=$(echo "$CONTEXT_INFO" | grep -o "[0-9.]\+k/[0-9.]\+k" | sed 's/k//g')
    USED=$(echo "$USAGE" | cut -d'/' -f1)
    TOTAL=$(echo "$USAGE" | cut -d'/' -f2)
    
    if [ -n "$USED" ] && [ -n "$TOTAL" ]; then
        PERCENT=$(echo "scale=1; $USED / $TOTAL * 100" | bc)
        echo "  使用率: ${PERCENT}%"
        
        # 检查是否需要压缩
        if (( $(echo "$PERCENT >= 70" | bc -l) )); then
            echo "⚠️  建议: 上下文使用率较高 (>70%)，建议压缩"
        elif (( $(echo "$PERCENT >= 50" | bc -l) )); then
            echo "ℹ️  状态: 使用率适中"
        else
            echo "✅ 状态: 使用率正常"
        fi
    fi
fi

if [ -n "$TOKEN_INFO" ]; then
    echo "🔤 Token 使用: $TOKEN_INFO"
fi

if [ -n "$CACHE_INFO" ]; then
    echo "💾 缓存状态: $CACHE_INFO"
fi

if [ -n "$COST_INFO" ]; then
    echo "💰 当前成本: $COST_INFO"
fi

if [ -n "$COMPACTIONS" ]; then
    echo "🔄 压缩次数: $COMPACTIONS"
fi

echo ""
echo "🎯 建议操作:"
echo "1. 使用率 >70%: 考虑压缩上下文"
echo "2. 使用率 >80%: 建议立即压缩"
echo "3. 使用率 >90%: 必须压缩，避免超出窗口"

# 提供压缩命令建议
echo ""
echo "🛠️ 压缩命令:"
echo "openclaw session_status  # 查看状态"
echo "# 手动压缩需要重启会话或等待自动压缩"
echo "# 或使用 context-manager 技能进行管理"