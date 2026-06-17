---
name: reviewing-code
description: Reviews diffs, PRs, commits, staged changes, or code snippets for correctness, regression risk, and test gaps. Use when the user asks for review, says "is this safe to merge"/"看一下风险"/"review 一下"/"帮我审审"/"有没有问题", or shares a diff/commit/snippet for risk assessment. Skip for:implementing changes, debugging an active failure, or planning.
---

# Reviewing Code

## Core Principle

Review 是找风险，不是复述改动。先列 findings，再给总结。**没有证据的猜测不当 finding，进 Open Questions。**

## 适用范围

优先用于：

- 用户说 review、代码评审、看改动、查风险、是否安全合并
- PR、diff、commit、staged changes、代码片段
- 判断是否缺测试、是否有回归

不要用于：

- 用户只要解释代码：用 `reading-code`
- 用户要先 review 再实现修复：先走本 Skill，得到确认后再切换 `building` 或 `debugging`

## 强制流程

### 1. 明确审查对象

必须知道：

- 审查范围：文件、diff、PR、commit、片段
- 目标行为：这次改动想达成什么
- 运行环境和关键配置
- 是否已有测试或验证结果

信息缺失时先补齐，不直接出 finding。

### 2. 风险优先审查（六维度，按顺序）

1. **正确性**：逻辑、边界、空值、异常、并发、时序
2. **回归**：旧行为、调用方、兼容接口、持久化数据
3. **数据**：字段、类型、单位、排序、过滤、聚合、时区、精度
4. **结构**：职责边界、重复、抽象、依赖方向
5. **安全**：输入验证、注入、权限、秘密、路径、XSS/CSRF
6. **验证**：测试覆盖、构建、lint、手动路径

每个维度必须给出"已检查"或"已检查无问题"的证据，不能跳过。

### 3. 中段自检

写 findings 前必须确认：

- [ ] 六个维度每个都实际看过（声明"已检查"也算，但要说明检查路径）
- [ ] 是否在没有证据时就写了 finding？如有，移到 Open Questions

### 4. 写 findings

每条 finding 必须包含：

- **等级**（Critical / Major / Minor，定义见下）
- **位置**：文件:行
- **问题**：具体描述
- **影响**：会怎么坏
- **触发场景**：什么输入/状态/时序触发
- **修复方向**：具体到可实施

### 5. Final Gate

输出前确认：

- [ ] 每条 finding 有完整六字段
- [ ] 没有触发"禁止输出模式"任一行
- [ ] 测试和验证覆盖维度有结论
- [ ] 没看完整审查范围却下了"无问题"结论

任一未通过 → 回 Step 2/4 补做，禁止输出。

## 严重级别

- **Critical**：会导致运行失败、数据损坏、安全漏洞、明显生产回归
- **Major**：高概率边界错误、重要测试缺口、结构风险会影响维护
- **Minor**：低风险可维护性、可读性、局部质量问题

## 检查门

以下情况不得输出"没问题"：

- 没看完整审查范围
- 没检查测试和验证缺口
- 没说明检查过哪些关键路径
- 不理解业务意图却直接判断安全
- 只提风格问题没看行为风险

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "整体没问题" | 列出检查过的路径和剩余风险，或写"未发现 finding，未覆盖维度：X" |
| "建议多加测试" | 指出具体缺哪条测试路径 |
| "可能有问题" | 给出触发条件和证据，或放 Open Questions |
| "代码质量不错" | 如无 finding，直接说未发现问题和未覆盖风险 |
| "这只是风格问题" | 说明是否会影响行为或维护成本 |
| "应该是安全的" | 列出已检查的输入路径和注入面 |

## 输出格式

```markdown
## Findings

1. [Critical/Major/Minor] `文件:行`
   - 问题：
   - 影响：
   - 触发场景：
   - 修复方向：

## Open Questions

- <未能定论的猜测，写明缺什么证据>

## 维度覆盖

- 正确性：<已检查 X，未发现/finding 数>
- 回归：...
- 数据：...
- 结构：...
- 安全：...
- 验证：...

## Summary

[一句话总结；无 finding 时说明未发现问题和剩余风险]
```
