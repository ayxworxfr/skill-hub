---
name: planning
description: Plans coding solutions, multi-step feature decomposition, and third-party dependency selection for AI-assisted coding. Produces a tier-appropriate execution card (alignment / solution / design) consumed by the building skill as task contract — covering intent, decision-driver elicitation via AskUserQuestion, project facts, code-level constraints, candidate comparison, change-scope, caller-grep evidence, structural-vs-behavioral split, diff budget, failure-mode mapping, and verification. Use when the user asks for a plan/方案/设计/思路/选型/取舍/几种做法, says "don't write code yet"/"先别写代码"/"先想清楚", requests multi-file or multi-step refactor decomposed into AI-iterable slices, or wants to add/replace a third-party library.
---

# Planning（编程方案规划）

## Core Principle

规划 = 在写代码前，把"做什么 / 为什么 / 怎么做 / 怎么验证"写清楚，**产出可被 building skill 消费的执行卡**作为任务契约。

锚定原则（每条都是动词）：

- **挖意图**：把用户原话翻译成 Job-to-be-Done，不复述
- **先问 driver 再列方案**：影响推荐的关键变量必须 asked 或 inferred-with-evidence，禁用"假设"绕过
- **引项目事实**：每条事实指向具体文件 / 函数（防 hallucination），优先于通用最佳实践
- **列 ≥2 候选 + Decision Drivers 评分**：trade-off 不靠主观感觉
- **标影响范围**（局部 / 跨模块 / 公开接口）：决定 commit 拆法 + 该不该先确认
- **预判失败模式 + 一一映射验证**：每条预判都有可执行验证（优先转 RED 测试）
- **写 diff 预算**：行数 + 文件数量级（防 scope creep / over-engineering）
- **拆 S/B 顺序**（设计卡级 Tidy First）：结构改与行为改不能同 commit

## 子模式判定（先做这一步）

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| "做个方案" / "几种做法" / "怎么设计" / "选哪个" / "取舍" / "技术选型"（非依赖） | **design** | [solution-design.md](references/solution-design.md) |
| 跨多文件 / 分阶段 / 大特性拆解 / 重构迁移 / 长链路改造 | **large** | [large-feature-delivery.md](references/large-feature-delivery.md) |
| 找三方库 / SDK / npm / PyPI / Maven / Cargo 包 / 替换依赖 | **deps** | [dependency-selection.md](references/dependency-selection.md) + [dependency-evaluation.md](references/dependency-evaluation.md) |

不确定时按 design 走；命中关键词再升级。读对应 reference 后再展开。

## 共用 reference

所有子模式必读：

- [clarifying-questions.md](references/clarifying-questions.md) — 决策驱动变量识别 + AskUserQuestion 用法 + 反例

design / large 必读：

- [code-quality.md](references/code-quality.md) — 代码级 6 类约束（性能 / 并发 / 可维护 / 可靠 / 安全 / 兼容）
- [failure-modes.md](references/failure-modes.md) — code-level pre-mortem + 失败模式 ↔ 验证映射

deps 子模式自有八维评估，可选读 code-quality / failure-modes。

## 三档产物（先选一档）

| 档位 | 适用 | 长度 | 必备 |
|---|---|---|---|
| **对齐卡** | 单文件 / 局部 bug / 简单加法 | 半页 | 意图 + Non-Goals + 命中约束 1-2 项 + 失败模式 + 验证 + 推荐 + 边界 |
| **方案卡** | 跨文件特性 / 选型 / 多步骤 | 1-2 页 | 上述 + 项目事实引用 + 2-3 候选 + Decision Drivers + 影响范围 + **diff 预算** + 切片（large） |
| **设计卡** | 改公开 API / 引入新基础依赖 / 架构级 | 3-5 页 | 上述 + **调用方 grep 结果** + **S/B 拆分** + 决策记录段 + Open Questions |

档位选错代价：重决策当对齐卡写 → 漏边界、公开接口踩坑；轻决策当设计卡写 → 浪费时间没人看。

子模式映射：design 按规模选三档；large 方案卡起步，跨多模块或改公开接口升设计卡（含 Walking Skeleton 第一刀）；deps 方案卡。

## 强制流程

### 1. 挖真实意图（Job-to-be-Done）

把用户"想要"翻译成 Job：

```text
当 [场景 / 触发条件]，
用户想要 [完成的任务 / 动机]，
以便 [可观察的结果]。
```

主动识别：

- 表面要求 vs 背后目标
- 当前痛点（可推断 + 标记"假设"）
- 不做会怎样
- 用户可能没意识到的相邻问题

不要一上来列方案。

### 2. 收项目事实（不是通用最佳实践）

规划必须基于当前代码。grep / read 实际文件，每条事实必须能引用到具体路径：

- 目录结构、模块边界、依赖方向
- 已有同类实现（grep 关键字 / 函数名 / 类名）
- 历史决策（git log、相关注释、已有方案）
- 数据模型、接口契约、错误处理风格、测试方式
- 用户偏好、禁区、长期目标

无项目事实引用 → 回此步，不允许进入推荐。

**改公开接口的方案**（设计卡级别）必须额外提供：

- 调用方 grep 结果（具体文件:行号 列表）
- 至少抽样 3 个调用方读其上下文，确认改动影响

### 2.5. 决策驱动变量识别 + 强制问答

进入候选对比 / 切片清单 / 健康度评估之前，必须把"会改变最终推荐"的变量解决。详见 [clarifying-questions.md](references/clarifying-questions.md)。

逐变量分类：

- **driver（不可推断）** → 用 AskUserQuestion 工具问；优先多选，每个 description 写 implication；一次最多 4 题
- **driver（可推断）** → grep / read 项目代码 / git log / 已加载 memory，引用证据并标"待用户否决"
- **边角** → 标"假设"，不必问

先查再问的顺序：项目代码 → git log → memory → README → 查不到才问，避免重复打扰。

硬门：driver 变量未解决（asked 或 inferred-with-evidence）→ 不得进入 Step 6 子模式展开，也不得给最终推荐。

### 3. 写 Goals / Non-Goals / 成功标准 / diff 预算

- **Goals**：可量化或可观察的成果（不是"提升体验"）
- **Non-Goals**：显式列出本次合理但不做的（防 AI 越界 / scope creep）
- **成功标准**：每个 Goal 对应可验证的现象 / 命令
- **输入 / 输出**：数据 / 接口 / 文件 / UI / 命令 / 副作用
- **约束**：技术栈 / 风格 / 性能 / 兼容
- **决策点**：哪些需要用户拍板
- **diff 预算**（方案卡 / 设计卡必填，对齐卡可选）：预期改动文件数（量级，如 1-2 / 3-5 / 5-10）+ 预期改动行数（量级，如 <50 / 50-200 / 200+）；触及未列文件 → building 必须停下报告

关键缺口按 Step 2.5 分类处理：driver 类必须 AskUserQuestion 或引用项目事实，不允许"假设"绕过；边角类才可标"假设"略过。

### 4. 选档位

按方案规模选 对齐卡 / 方案卡 / 设计卡。后续展开严格按档位裁剪。

### 5. 识别代码级约束（NFR-lite）

加载 [code-quality.md](references/code-quality.md)。逐项过 6 类约束（性能 / 并发 / 可维护 / 可靠 / 安全 / 兼容），命中项写：

- **约束**（具体场景）
- **检查方式**（可执行命令 / 可观察现象）

非命中项可省略。档位差：对齐卡通常 1-2 项；方案卡列 #1/#2 优先；设计卡完整覆盖。

### 6. 子模式展开

按子模式加载对应 reference 并执行：

- **design**：发散思路 → 2-3 候选 → Decision Drivers 评分 → 影响范围分类 → 推荐（公开接口变更附调用方 grep）
- **large**：范围收敛 → **Walking Skeleton 第一刀** → 垂直切片 → 切片清单 → 进入 / 完成条件
- **deps**：联网查候选 → 健康度八维 → 项目适配 → 接入验证

设计卡级别额外做 **结构改 vs 行为改 拆分**（Tidy First）：S 类（结构，不改行为）+ B 类（行为）两类，顺序 S 先 → 测试 → B → 测试，各自一次 commit。

### 7. 失败模式预判 + 验证映射

加载 [failure-modes.md](references/failure-modes.md)。强制 code-level pre-mortem：

1. 假设 AI 按这个方案写完代码，最有可能哪里出 bug？
2. 写 ≥3 条具体失败模式（场景 + 原因 + 后果）
3. 每条对应一个可执行验证项（优先转 RED 测试）
4. High 级（崩溃 / 数据丢失 / 安全漏洞 / 公开接口破坏）必须有针对性测试

输出：失败模式 ↔ 验证项 表格。无映射 → 回此步。

### 8. 中段自检（第二层防御）

进入推荐前确认：

- [ ] 真实意图 / Non-Goals / 成功标准 已写出（非用户原话复述）
- [ ] 决策驱动变量已 asked 或 inferred-with-evidence（无"假设"绕过 driver）
- [ ] 项目事实有具体路径引用
- [ ] 改公开接口时调用方 grep 已列（设计卡）
- [ ] 档位已选定且与规模匹配
- [ ] 方案卡 / 设计卡 含 diff 预算
- [ ] 代码级约束识别覆盖命中项
- [ ] 子模式 reference 已加载并执行
- [ ] large 含 Walking Skeleton 第一刀边界
- [ ] 设计卡 含 S/B 拆分顺序
- [ ] 失败模式 ≥3 条且每条有验证项

任一未通过 → 回对应步骤，禁止前进。

### 9. 收敛推荐（产出执行卡）

必须说明：

- **推荐**哪个方案 / 切片顺序 / 候选库
- **Decision Drivers 评分对比**
- **为什么选它**（逐 Driver 解释，不是"分数高"）
- **为什么不选其他**（文字理由）
- **影响范围**（局部 / 跨模块 / 公开接口）
- **diff 预算**（行数 + 文件数量级）
- **调用方 grep 结果**（设计卡，公开接口变更）
- **S/B 拆分顺序**（设计卡）
- **下一步实施边界**（building 接下来做什么、不做什么 → 直接当任务契约）
- **验证计划**（具体命令 / 现象 / 通过条件，优先 RED 测试）
- **重评估条件**（什么变化时该回头改决策）

信息不足 → 输出"暂不推荐最终方案"，列还缺什么，不硬拍。

### 10. 决策记录段（仅设计卡）

设计卡需要一段决策记录（不是 ADR governance，没有状态流转 / supersede 链）：

- 标题 / 日期 / 上下文与问题 / Decision Drivers / 候选与权衡 / 决策结果 / 正负面后果 / 重评估条件

作用：给未来 AI / 人留个"为什么这么做"的小段，几十行内。

## 共用禁止输出

| 禁止 | 替代 |
|---|---|
| "两种方案都可以" / "都行" | 推荐一个，说明前提与影响范围 |
| "看团队偏好" / "看个人喜好" | 列具体 Decision Drivers |
| "先做简单版" | 标明对齐卡 / Walking Skeleton；写后续切片 |
| "后续可扩展" | 写具体扩展点 + 当前不做原因 + 重评估条件 |
| "风险不大" / "应该没问题" | 引用失败模式表 + 对应验证 |
| "需求不明确所以没法设计" | 用 AskUserQuestion 问 driver；只对边角才出"假设版" |
| "假设：[driver 变量]=X" | 用 AskUserQuestion 问 X，或引用项目事实 / memory 推断 |
| "团队偏好不清楚所以先假设" | 查 memory / 历史决策；查不到用 AskUserQuestion 问 |
| "最佳实践是 X" | 说明它是否契合本项目事实 |
| "方案 A 更优雅" | 写 Decision Driver 评分 + 牺牲了什么 |
| "性能没问题" | 写代码级约束 + 检查方式 |
| "改一下函数签名应该没影响" | 列调用方 grep 结果 + 抽样上下文 |
| "AI 写的时候自己注意" | 写明确检查项 + 验证命令 + diff 预算 |
| "结构和功能一起改了" | 拆 S/B 两类，分别 commit |

## Final Gate（第三层防御）

输出前对自己的回答执行扫描动作（不是再过一遍 Step 8 清单）：

1. **扫"假设"字面量**：搜自己输出里有没有"假设：[driver 变量]=X"——有则回 Step 2.5 改成 AskUserQuestion 或事实引用
2. **扫"共用禁止输出"表第 1 列字面量**：每条字面量都不应在自己输出里出现；命中即回对应步骤改写
3. **扫"项目事实"段**：每条事实必须能跳转到具体文件:行；无路径引用即不算事实
4. **扫"失败模式与验证"段**：≥3 行 + 每行有"验证项"列填具体命令/测试；High 级标 "RED: yes"
5. **扫推荐段**：含"为什么选它（逐 Driver）"+"为什么不选其他"+"影响范围"+"下一步实施边界"——四件齐全
6. **按子模式扫专属字段**：design 的候选表、large 的 Walking Skeleton 完成标志、deps 的健康度八维 + 安装命令——按子模式 reference 末尾"输出片段"对照

任一扫描发现违规不得输出。

## 输出骨架

按档位裁剪，主章节顺序固定：

```markdown
## 意图与边界
- Job-to-be-Done：
- Goals / Non-Goals / 成功标准：

## 决策驱动变量
| 变量 | 类别（driver / 边角） | 取值 | 来源（用户回答 / memory / 项目事实路径 / 假设） |
|---|---|---|---|

## 项目事实
- <文件 / 函数 / 模块 引用>
- 已有同类实现 / 关键约束 / 调用方 grep（设计卡）

## 档位
- 选定：对齐卡 / 方案卡 / 设计卡
- 选档理由：

## diff 预算（方案卡 / 设计卡必填）
- 文件数 / 行数 量级

## 代码级约束（命中项）
- 性能 / 并发 / 可维护 / 可靠 / 安全 / 兼容（按命中写，含约束 + 检查方式）

## 子模式展开
<按 reference：候选对比 / Walking Skeleton + 切片清单 / 依赖评估>

## S/B 拆分（设计卡）
- 结构改（S）/ 行为改（B）/ 顺序：S → 测试 → B → 测试

## 失败模式与验证
| 失败模式 | 级别 | 验证项（优先 RED 测试） |
|---|---|---|

## 推荐与决策
- 推荐 / Drivers 评分 / 为什么选它（逐 Driver） / 为什么不选其他
- 影响范围 / diff 预算 / 下一步实施边界 / 重评估条件

## 决策记录（仅设计卡）
- 上下文 / Drivers / 决策结果 / 后果 / 重评估条件
```

不能省的核心字段（无论档位）：意图、决策驱动变量、Non-Goals、项目事实引用、命中约束、失败模式与验证、推荐理由、影响范围、下一步实施边界。

子模式专属输出片段（候选表 / Walking Skeleton 切片清单 / 依赖评估表）见对应 reference。
