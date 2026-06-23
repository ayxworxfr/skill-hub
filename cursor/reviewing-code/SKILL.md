---
name: reviewing-code
description: Reviews diffs, PRs, commits, staged changes, or code snippets for correctness, regression risk, and test gaps. Use when the user asks for review, says "is this safe to merge"/"看一下风险"/"review 一下"/"帮我审审"/"有没有问题", or shares a diff/commit/snippet for risk assessment. Skip for:implementing changes, debugging an active failure, or planning.
---

# Reviewing Code

## Core Principle

Review 是找风险，不是复述改动。先列 findings，再给总结。**没有证据的猜测不当 finding，进 Open Questions。**

锚定原则（**唯一完整声明**，下文按编号引用，不复述）：

- **P1 找风险**：不复述改动；改动了什么 diff 自证，review 只输出风险
- **P2 有证据**：每条 finding 必须能引用具体 文件:行 + 触发场景；无证据进 Open Questions
- **P3 六维度**：正确性 / 回归 / 数据 / 结构 / 安全 / 验证，详 [review-dimensions.md](references/review-dimensions.md)，每维度都要给"已检查"或"已检查无问题"的证据
- **P4 finding 六字段**：等级 / 位置 / 问题 / 影响 / 触发场景 / 修复方向，缺一不可
- **P5 联动反模式扫描**：先跑 [scan_review_signals.py](scripts/scan_review_signals.py) 出候选清单，再人工判定；这是与 [building](../building/SKILL.md) §3.1 R 表的固定联动
- **P6 范围闭合**：所有声明的审查范围必须实际看过；未看完不得说"无问题"

## 适用范围

优先用于：

- 用户说 review / 代码评审 / 看改动 / 查风险 / 是否安全合并
- PR / diff / commit / staged changes / 代码片段
- 判断是否缺测试 / 是否有回归

不要用于：

- 用户只要解释代码：用 [reading-code](../reading-code/SKILL.md)
- 用户要先 review 再实现修复：先走本 skill，得到确认后再切换 [building](../building/SKILL.md) / [debugging](../debugging/SKILL.md)
- 用户要做提交 / push / PR 操作：用 [git-safety](../git-safety/SKILL.md)

## 1. 决策框架

### 1.1 任务规模档位

| 档位 | 触发条件（全部满足） | 流程 |
|---|---|---|
| **Trivial** | 改动 ≤ 20 行 / 单文件 / 单逻辑分支 / 无新依赖 / 不涉及敏感文件 | 跳过 §2.2 上下文拉取 / 跳过 §2.3 维度全扫，直接出 finding |
| **Standard** | 其他情况 | §2 完整流程 |

**不确定时往上走一档，绝不下降。**

### 1.2 输入形态识别

| 输入 | 拉取方式 |
|---|---|
| PR URL | `gh pr view <url> --json files,additions,deletions,body` + `gh pr diff <url>` |
| commit / commit range | `git show <sha>` / `git diff <from>..<to>` |
| staged changes | `git diff --cached` |
| 用户贴代码片段 | 直接审；上下文不足时先问，不臆测 |

## 2. 执行流程

### 2.1 明确审查对象

按 P6 必须知道：

- **审查范围**：文件清单 + 行数 + 修改类型（新增 / 修改 / 删除）
- **目标行为**：这次改动想达成什么（看 PR description / commit message / 用户描述）
- **运行环境和关键配置**：影响哪个环境 / 是否有 feature flag / 是否有迁移
- **是否已有测试或验证结果**：CI 状态 / 测试覆盖路径

信息缺失时先补齐，不直接出 finding。

### 2.2 拉取上下文（Standard 档必做）

按 P5 跑：

```bash
python <skills-dir>/reviewing-code/scripts/scan_review_signals.py \
  --diff "<diff-file>" \
  --output finding-candidates.json
```

脚本扫描（详见脚本注释）：

- 敏感文件模式（联动 [git-safety](../git-safety/SKILL.md) §安全规则）
- building R 表 AI 反模式关键词（silent fake success / try-pass / 占位 TODO / 调试残留）
- 大文件（>500KB） / 二进制 / lock 文件
- 测试文件断言改动（R7 修测试让代码通过的候选）

辅助命令：

- `git log --oneline -20 -- <file>`：查文件最近改动史
- `git blame <file>`：查涉及代码段的历史作者和动机
- `gh pr view <url> --json reviewComments`：查已有 review 意见，避免重复

### 2.3 六维度审查

加载 [review-dimensions.md](references/review-dimensions.md)，按顺序过：

1. **正确性**：逻辑、边界、空值、异常、并发、时序
2. **回归**：旧行为、调用方、兼容接口、持久化数据
3. **数据**：字段、类型、单位、排序、过滤、聚合、时区、精度
4. **结构**：职责边界、重复、抽象、依赖方向
5. **安全**：输入验证、注入、权限、秘密、路径、XSS/CSRF
6. **验证**：测试覆盖、构建、lint、手动路径

每个维度必须给出"已检查"或"已检查无问题"的证据，不能跳过（P3）。每个维度的细化检查动作、命中模式、典型 finding 模板见 reference。

### 2.4 中段自检

写 findings 前 checkbox 全过：

- [ ] §2.2 扫描脚本已跑，候选清单已逐条判定
- [ ] 六维度每个都实际看过，能引用检查路径（P3）
- [ ] 没有在无证据时写 finding；猜测都移到 Open Questions（P2）
- [ ] 审查范围内的文件全部看过（P6）
- [ ] PR 类型识别清楚（feature / refactor / bugfix / migration / dependency / config），按类型重点已对齐

任一未通过 → 回 §2.2-2.3 补；不得直接进 §2.5。

### 2.5 撰写 findings

按 P4 每条 finding 六字段齐全：

- **等级**（Critical / Major / Minor，定义见 §4）
- **位置**：文件:行
- **问题**：具体描述
- **影响**：会怎么坏（运行时崩 / 数据损坏 / 安全漏洞 / 测试缺口 / 维护成本）
- **触发场景**：什么输入 / 状态 / 时序触发
- **修复方向**：具体到可实施

排序：Critical > Major > Minor；同档内按风险大小。

## 3. 质量门

### 3.1 Finding 质量硬阻断表（唯一完整声明）

撰写 findings 时任一命中 → 该条不得输出。下文 Final Gate 按编号引用，不复述：

| # | 反模式 | 触发信号 | 替代动作 |
|---|---|---|---|
| **F1** | 无证据猜测当 finding | "可能 / 也许 / 似乎"无 文件:行 支撑 | 移到 Open Questions（P2） |
| **F2** | 复述改动当 finding | finding 描述等同于"这里改了 X" | 删；改动用 diff 自证（P1） |
| **F3** | 字段不齐 | 六字段缺任一（等级 / 位置 / 问题 / 影响 / 触发场景 / 修复方向） | 补齐再输出（P4） |
| **F4** | 等级与影响错位 | 影响是数据损坏却标 Minor / 影响是命名却标 Critical | 按 §4 严重级别表重判 |
| **F5** | 维度遗漏 | 输出未提及某维度的检查结果 | 补"已检查 X，未发现"或具体 finding（P3） |
| **F6** | 越界审查 | 评论审查范围外的文件 / 行 | 删；范围外问题放 Open Questions 提示 |

### 3.2 Final Gate

输出前扫流程层级三件事。任一违规不得声称完成：

1. **扫维度覆盖**（P3 + F5）：6 维度每个都有"已检查"结论或具体 finding，无遗漏
2. **扫脚本联动**（P5）：Standard 档已跑 scan_review_signals.py，候选清单逐条有判定结果
3. **扫范围闭合**（P6 + F6）：声明的审查范围全部看过，无未审查文件；越界评论已删

## 4. 严重级别

| 等级 | 定义 | 影响示例 |
|---|---|---|
| **Critical** | 会导致运行失败、数据损坏、安全漏洞、明显生产回归 | NPE 在主路径触发 / SQL 注入 / 密钥泄漏 / 迁移会丢数据 / 调用方未同步导致编译失败 |
| **Major** | 高概率边界错误、重要测试缺口、结构风险影响维护 | 边界条件遗漏（仅在偶发输入触发崩溃） / High 级失败模式无测试覆盖 / 核心逻辑职责严重错位 |
| **Minor** | 低风险可维护性 / 可读性 / 局部质量问题 | 命名不一致 / 注释过时 / 局部重复 / Minor 级失败模式无测试 |

判定决策：

- **影响 + 触发概率**：Critical = 高影响 + 高概率；Major = 高影响 + 低概率 或 中影响 + 高概率；Minor = 低影响 或 极低概率
- **PR 类型差异**：migration / dependency / config 类 PR 中"可能丢数据 / 服务中断"按 Critical；feature 类 PR 中"边界遗漏"按 Major

## 5. 共用禁止输出

| 禁止输出 | 替代动作 |
|---|---|
| "整体没问题" / "代码质量不错" | 列已检查的路径 + 未覆盖维度，或写"未发现 finding，未覆盖维度：X" |
| "建议多加测试" | 指出具体缺哪条测试路径 + 期望断言 |
| "可能有问题" / "应该是安全的" | 给出证据，或移 Open Questions（F1） |
| "这只是风格问题" | 说明是否影响行为或维护成本；只影响可读性标 Minor |
| "都改了一遍 LGTM" | 列六维度结论 + 已审范围（P6） |
| "改了好多，重点看了关键的" | 列实际审查的文件清单 + 未审清单（F6） |

## 6. 输出骨架

```markdown
## 审查对象
- 范围：<文件清单 + 行数 + 类型>
- 输入形态：<PR / commit / diff / 片段>
- PR 类型：<feature / refactor / bugfix / migration / dependency / config>
- 目标行为：<引用 PR description / commit msg / 用户描述>

## 上下文拉取
- scan_review_signals.py 候选数：<N>
- 关键历史改动：<git log / blame 关键行>
- 已有 review 意见：<避免重复>

## Findings

### 1. [Critical / Major / Minor] `文件:行`
- 问题：
- 影响：
- 触发场景：
- 修复方向：

### 2. ...

## Open Questions

- <未能定论的猜测 / 缺什么证据 / 范围外提示>

## 维度覆盖

- 正确性：<已检查 X，未发现 / finding #>
- 回归：<已检查 X，未发现 / finding #>
- 数据：<已检查 X，未发现 / finding #>
- 结构：<已检查 X，未发现 / finding #>
- 安全：<已检查 X，未发现 / finding #>
- 验证：<已检查 X，未发现 / finding #>

## Summary

<一句话总结；无 finding 时说明未发现问题和剩余风险>
```
