---
name: context-manager
description: 定时检查 OpenClaw 上下文窗口负载，在负载过高时主动压缩上下文，优化 token 使用和成本控制。
---

# Context Manager Skill

## 目的
自动监控 OpenClaw 会话的上下文窗口负载，在负载过高时触发主动压缩，优化 token 使用效率和控制成本。

## 工作原理

### 监控指标
1. **上下文使用率** - 当前已使用 tokens / 总上下文窗口
2. **缓存命中率** - 缓存 tokens 命中比例
3. **Token 成本** - 当前会话的累计成本
4. **压缩历史** - 已执行的压缩次数

### 触发条件
当满足以下任一条件时触发主动压缩：

| 条件 | 阈值 | 说明 |
|------|------|------|
| 上下文使用率 | ≥70% | 负载较高，接近窗口上限 |
| 缓存命中率 | ≤20% | 缓存效率低，需要优化 |
| 连续对话 | ≥20轮 | 长时间对话，需要清理 |
| 成本预警 | ≥$0.50 | 成本控制需要 |

### 压缩策略
1. **轻度压缩** (70-80%) - 保留最近10轮对话
2. **中度压缩** (80-90%) - 保留最近5轮对话  
3. **重度压缩** (≥90%) - 保留最近3轮对话，清理历史

## 使用方式

### 手动检查
```bash
# 检查当前上下文状态
context-manager check

# 强制压缩上下文
context-manager compress

# 查看压缩历史
context-manager history
```

### 定时任务配置
```bash
# 每30分钟检查一次
context-manager schedule --every 30m

# 每天特定时间检查
context-manager schedule --cron "0 */2 * * *"
```

### 集成到现有系统
```bash
# 在技能同步前检查上下文
sync-skill validate <skill> && context-manager check

# 在长时间任务后压缩
long-running-task && context-manager compress
```

## 配置选项

### 阈值配置
```json
{
  "context_threshold": 0.7,
  "cache_threshold": 0.2,
  "cost_threshold": 0.5,
  "rounds_threshold": 20
}
```

### 压缩策略
```json
{
  "light_compress": {"keep_rounds": 10},
  "medium_compress": {"keep_rounds": 5},
  "heavy_compress": {"keep_rounds": 3}
}
```

## 输出示例

### 检查报告
```
📊 Context Status Report
├── Usage: 65k/131k (50%)
├── Cache: 29% hit (17k cached)
├── Cost: $0.12
├── Rounds: 15
└── Status: ✅ Healthy (no compression needed)
```

### 压缩通知
```
🔄 Context Compression Triggered
├── Reason: Usage reached 78%
├── Strategy: Light compression
├── Kept: Last 10 conversation rounds
└── Result: Usage reduced to 45%
```

## 集成建议

### 与现有技能结合
1. **skill-sync** - 在同步前检查上下文
2. **hotspot-market-briefing** - 在生成报告后压缩
3. **定时任务** - 定期维护上下文健康

### 最佳实践
1. **定期检查** - 每30-60分钟检查一次
2. **事件驱动** - 在关键操作前后检查
3. **成本控制** - 监控并控制会话成本
4. **性能优化** - 保持缓存效率

## 故障排除

### 常见问题
1. **压缩无效** - 检查会话权限和配置
2. **阈值不触发** - 验证阈值设置和监控频率
3. **成本计算偏差** - 确认模型定价配置

### 调试命令
```bash
# 详细调试信息
context-manager check --verbose

# 模拟压缩测试
context-manager compress --dry-run

# 查看详细日志
context-manager logs
```

## 安全考虑
- 只压缩当前会话上下文
- 保留关键系统消息和用户指令
- 不删除重要记忆和配置
- 提供压缩前的状态备份

---

**维护提示：** 定期检查阈值设置，根据实际使用模式调整压缩策略。