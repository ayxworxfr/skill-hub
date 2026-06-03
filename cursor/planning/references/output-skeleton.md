# Planning 输出骨架（按档位裁剪）

planning skill 的输出统一遵循以下骨架；按档位（对齐卡 / 方案卡 / 设计卡）裁剪对应章节。

## 完整骨架

```markdown
## 意图与边界
- Job-to-be-Done：
- 当前痛点：
- Goals：
- Non-Goals：
- 成功标准：

## 项目事实
- <文件 / 函数 / 模块 引用>
- 已有同类实现：
- 关键约束：
- 假设（待确认）：
- 调用方 grep（公开接口变更，设计卡）：

## 档位
- 选定：对齐卡 / 方案卡 / 设计卡
- 选档理由：

## diff 预算（方案卡 / 设计卡必填）
- 预期改动文件数：<量级>
- 预期改动行数：<量级>

## 代码级约束（命中项）
- 性能 / 并发 / 可维护 / 可靠 / 安全 / 兼容（按命中写）

## 子模式展开
<按 reference 输出：候选对比 / Walking Skeleton + 切片清单 / 依赖评估>

## S/B 拆分（设计卡）
- 结构改（S）：<动作；不改测试>
- 行为改（B）：<动作>
- 顺序：S → 测试 → B → 测试

## 失败模式与验证
| 失败模式 | 触发场景 | 验证项（优先 RED 测试） |
|---|---|---|
| ... | ... | <命令 / 测试 / 现象> |

## 推荐与决策（→ building 任务契约）
- 推荐：
- Decision Drivers 评分：
- 为什么选它（逐 Driver）：
- 为什么不选其他：
- 影响范围：局部 / 跨模块 / 公开接口
- 需要用户确认：
- 下一步实施边界：
- 重评估条件：

## 决策记录（仅设计卡）
- 上下文 / Drivers / 决策结果 / 后果 / 重评估条件
```

## 档位裁剪规则

| 档位 | 必备章节 |
|---|---|
| **对齐卡** | 意图 + Non-Goals + 命中约束 1-2 项 + 失败模式 + 验证 + 推荐 + 边界；半页内；diff 预算可选 |
| **方案卡** | 完整骨架；**含 diff 预算**；无 S/B 拆分；无决策记录段 |
| **设计卡** | 完整骨架 + **调用方 grep + S/B 拆分 + 决策记录段** + Open Questions |

## 不能省的核心字段

无论档位都不能省：

- 意图（Job-to-be-Done）
- Non-Goals
- 项目事实引用
- 命中约束
- 失败模式与验证
- 推荐理由（不是只说"分数高"）
- 影响范围
- 下一步实施边界（→ building 任务契约）

## 子模式专属输出片段

各子模式的具体输出片段（候选对比 / Walking Skeleton 切片清单 / 依赖评估）见对应 reference：

- design：见 [solution-design.md](solution-design.md) `## design 输出片段`
- large：见 [large-feature-delivery.md](large-feature-delivery.md) `## large 输出片段`
- deps：见 [dependency-selection.md](dependency-selection.md) 输出部分
