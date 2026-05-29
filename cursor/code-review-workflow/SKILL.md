---
name: code-review-workflow
description: Use when reviewing diffs, PRs, commits, staged changes, code snippets, merge readiness, regression risk, test gaps, or whether a change is safe.
---

# Code Review Workflow

## 目标

Review 是找风险，不是复述改动。先列 findings，再给总结。

## 适用范围

优先用于：

- 用户说 review、代码评审、看改动、查风险
- PR、diff、commit、staged changes、代码片段
- 判断是否安全、是否可合并、是否缺测试

不要用于：

- 用户要实现修复：先 review，得到确认后再切换开发或调试流程
- 用户只要解释代码：用 `code-understanding-workflow`

## 强制流程

### 1. 明确审查对象

必须知道：

- 审查范围：文件、diff、PR、commit、片段
- 目标行为：这次改动想达成什么
- 运行环境和关键配置
- 是否已有测试或验证结果

### 2. 风险优先审查

按顺序检查：

1. 正确性：逻辑、边界、空值、异常、并发、时序。
2. 回归：旧行为、调用方、兼容接口、持久化数据。
3. 数据：字段、类型、单位、排序、过滤、聚合、时区、精度。
4. 结构：职责边界、重复、抽象、依赖方向。
5. 安全：输入验证、注入、权限、秘密、路径、XSS/CSRF。
6. 验证：测试覆盖、构建、lint、手动路径。

### 3. 只报告有证据的问题

每条 finding 必须包含：

- 等级
- 位置
- 问题
- 为什么会坏
- 触发场景
- 修复方向

没有证据的猜测放到 Open Questions，不当 finding。

## 严重级别

- Critical：会导致运行失败、数据损坏、安全漏洞、明显生产回归。
- Major：高概率边界错误、重要测试缺口、结构风险会影响维护。
- Minor：低风险可维护性、可读性、局部质量问题。

## 检查门

以下情况不得输出“没问题”：

- 没看完整审查范围
- 没检查测试和验证缺口
- 没说明检查过哪些关键路径
- 不理解业务意图却直接判断安全
- 只提风格问题，没看行为风险

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| “整体没问题” | 列出检查过的路径和剩余风险 |
| “建议多加测试” | 指出具体缺哪条测试路径 |
| “可能有问题” | 给出触发条件和证据，或放 Open Questions |
| “代码质量不错” | 如无 finding，直接说未发现问题和未覆盖风险 |
| “这只是风格问题” | 说明是否会影响行为或维护成本 |

## 输出格式

```markdown
## Findings

1. [Critical/Major/Minor] `位置`
   问题：
   影响：
   触发场景：
   修复方向：

## Open Questions

- ...

## Summary

[一句话总结；无 finding 时说明未发现问题和剩余风险]
```
