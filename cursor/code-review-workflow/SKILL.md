---
name: code-review-workflow
description: Reviews code changes with a risk-first mindset that prioritizes bugs, regressions, edge cases, and missing tests. Use for pull request review, diff review, change risk assessment, and requests to check whether a code change is safe or merge-ready.
---

# Code Review Workflow

## 目标

把 review 做成“找问题”，而不是“复述改了什么”。

## 适用范围

优先用于以下场景：

- 用户说“review”
- 用户说“帮我看看改动”
- 用户发来 diff、PR、提交记录或代码片段
- 需要判断是否有 bug、回归风险或测试缺口

## 审查顺序

### 1. 先看行为风险

- 逻辑是否正确
- 旧行为是否可能被破坏
- 分支条件、边界值、空值、异常路径是否覆盖

### 2. 再看数据风险

- 字段映射是否正确
- 类型、单位、时区、金额、精度是否可能出错
- 写入、读取、过滤、排序、聚合是否可能偏离预期

### 3. 再看结构风险

- 是否引入不必要复杂度
- 是否破坏模块职责
- 是否让后续维护更难

### 4. 最后看验证缺口

- 是否缺回归测试
- 是否缺边界测试
- 是否只测了 happy path

## 输出要求

先列 findings，再写简短总结。

每条 finding 应包含：

- 严重级别
- 问题位置
- 为什么有风险
- 在什么场景下会出错

## 严重级别建议

- Critical：会导致错误结果、运行失败、数据损坏、明显回归
- Major：高概率边界问题、测试缺口大、结构风险高
- Minor：可维护性问题、可读性问题、低风险改进点

## 输出模板

```markdown
## Findings

1. [Critical] [位置]
   [问题与影响]

2. [Major] [位置]
   [问题与影响]

## Open Questions

- [需要确认的点]

## Summary

- [一句话总结]
```

## 审查原则

- 先找错，再总结
- 只提有依据的问题
- 重点说明“会怎么坏”
- 没发现问题时要明确说没有发现问题，并说明剩余风险

## 避免事项

- 不把 review 写成 changelog
- 不用“看起来还行”代替判断
- 不只提风格问题而忽略正确性问题
- 不因为代码复杂就跳过关键路径

## 触发信号

- “review”
- “代码评审”
- “看一下这个 PR”
- “这次改动有没有问题”
- “帮我查风险”
