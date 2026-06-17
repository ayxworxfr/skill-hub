---
name: planning
description: Plans coding solutions, multi-step feature decomposition, and third-party library selection. Use when the user asks for "plan"/"方案"/"设计"/"思路"/"选型"/"取舍"/"几种做法", says "don't write code yet"/"先别写代码"/"先想清楚", requests multi-file refactor decomposition, or wants to add/replace a library. Skip for:direct implementation requests, single-file edits, debugging, or code review.
---

# Planning（编程方案规划）

## Core Principle

规划 = 在写代码前，把"做什么 / 为什么 / 怎么做 / 怎么验证"写清楚，**产出可被 building skill 消费的执行卡**作为任务契约。

锚定原则（**唯一完整声明**，下文按编号引用，不复述）：

- **P1 挖意图**：把用户原话翻译成 Job-to-be-Done，不复述
- **P2 引项目事实**：每条事实指向具体文件 / 函数（防 hallucination），优先于通用最佳实践
- **P3 先问 driver 再列方案**：影响推荐的关键变量必须 asked 或 inferred-with-evidence，禁"假设"绕过
- **P4 列 ≥2 候选 + Decision Drivers 评分**：trade-off 不靠主观感觉
- **P5 标影响范围**：局部 / 跨模块 / 公开接口；改公开接口必须列调用方 grep
- **P6 失败模式 ≥3 + 验证映射**：每条预判有可执行验证（High 级转 RED 测试）
- **P7 写 diff 预算**：行数 + 文件数量级（防 scope creep / over-engineering）
- **P8 拆 S/B 顺序**：设计卡 Tidy First，结构改与行为改不同 commit
- **P9 命中即落盘**：见 [§3.1 推荐前硬阻断表](#31-推荐前硬阻断表唯一完整声明) H5

## 术语小词典

外来术语首次出现位置一行兜底，避免跨 skill 漂移：

| 术语 | 定义 | 来源 |
|---|---|---|
| Job-to-be-Done | "当 X，用户想做 Y，以便 Z" 三段式意图翻译 | 本 skill P1 |
| Decision Drivers | 选型时影响推荐的硬约束维度（性能 / 团队熟悉度 / 兼容性等） | 本 skill P4 |
| Walking Skeleton | 跨全栈最薄的端到端可运行切片（large 子模式第一刀） | [large-feature-delivery.md](references/large-feature-delivery.md) |
| 失败模式表 | code-level pre-mortem 的 High / Med / Low 三级失败枚举 + 对应验证 | [failure-modes.md](references/failure-modes.md) |
| driver 变量 / 边角变量 | driver = 影响推荐结论；边角 = 不影响最终方向，可标"假设" | [clarifying-questions.md](references/clarifying-questions.md) |
| 对齐卡 / 方案卡 / 设计卡 | 三档产物，承载"问题/范围对齐"、"方案选择"、"切片+失败模式" | 本 skill §1.3 |
| S 类 / B 类 commit | Kent Beck Tidy First：Structural（不改 user-visible 行为）/ Behavioral | [building](../building/SKILL.md) §2.5 |
| RED→GREEN | TDD 红绿循环：先写失败测试见红，再写实现见绿 | [building](../building/SKILL.md) P3 |

## 1. 决策框架

入口决策表：先判子模式，再选档位，最后判落盘。

### 1.1 是否走 planning

| 任务类型 | 走哪 |
|---|---|
| 做方案 / 几种做法 / 怎么设计 / 选哪个 / 取舍 / 技术选型（非依赖） | planning |
| 跨多文件 / 分阶段 / 大特性拆解 / 重构迁移 / 长链路改造 | planning |
| 找三方库 / SDK / npm / PyPI / Maven / Cargo 包 / 替换依赖 | planning |
| 直接实现 / 单文件改动 | [building](../building/SKILL.md) |
| 报错 / 异常 / 根因排查 | [debugging](../debugging/SKILL.md) |
| 代码审查 | [reviewing-code](../reviewing-code/SKILL.md) |

### 1.2 子模式判定

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| 做方案 / 几种做法 / 怎么设计 / 选哪个 / 取舍 / 技术选型（非依赖） | **design** | [solution-design.md](references/solution-design.md) |
| 跨多文件 / 分阶段 / 大特性拆解 / 重构迁移 / 长链路改造 | **large** | [large-feature-delivery.md](references/large-feature-delivery.md) |
| 找三方库 / SDK / npm / PyPI / Maven / Cargo 包 / 替换依赖 | **deps** | [dependency-selection.md](references/dependency-selection.md) + [dependency-evaluation.md](references/dependency-evaluation.md) |

不确定时按 design 走；命中关键词再升级。共用必读 [clarifying-questions.md](references/clarifying-questions.md)；design / large 必读 [code-quality.md](references/code-quality.md) + [failure-modes.md](references/failure-modes.md)；deps 自有八维评估，可选读后两者。

### 1.3 档位选择

| 档位 | 适用 | 长度 | 必备字段 |
|---|---|---|---|
| **对齐卡** | 单文件 / 局部 bug / 简单加法 | 半页 | 意图 + Non-Goals + 命中约束 1-2 项 + 失败模式 + 验证 + 推荐 + 边界 |
| **方案卡** | 跨文件特性 / 选型 / 多步骤 | 1-2 页 | 上述 + 项目事实引用 + 2-3 候选 + Decision Drivers + 影响范围 + **diff 预算** + 切片（large） |
| **设计卡** | 改公开 API / 引入新基础依赖 / 架构级 | 3-5 页 | 上述 + **调用方 grep 结果** + **S/B 拆分** + 决策记录段 + Open Questions |

子模式 → 档位映射：design 按规模选；large 方案卡起步，跨多模块或改公开接口升设计卡（含 Walking Skeleton 第一刀）；deps 方案卡。**档位选错代价**：重决策当对齐卡写 → 漏边界、公开接口踩坑；轻决策当设计卡写 → 浪费时间没人看。

### 1.4 落盘判定

**硬门**：触发任一条件时，必须 Write 工具落盘 MD 后才允许 building 开始编码（P9）。

| 档位 / 子模式 | 落盘？ |
|---|---|
| 对齐卡 | 否 |
| 方案卡（diff ≤ 50 行 + ≤ 3 文件 + 单次对话能完成） | 否 |
| 方案卡（其他） | **是** |
| 设计卡 | **是** |
| large 子模式 | **是** |
| deps 子模式 | 否 |

落盘规则：

- **路径**：`docs/astra/<YYYY-MM-DD>-<slug>.md`；目录不存在时先建。slug 用 kebab-case（如 `2026-06-11-user-auth-rewrite.md`）
- **一个需求一份文档**：不拆子目录、不拆"设计 + 评估"两份；后续修订直接 edit 原文档，不另起新文件
- **内容**：完整 §5 输出骨架，不删字段；设计卡含决策记录段
- **落盘后**：回复给绝对路径 + 一句话摘要，再交接 building

## 2. 执行流程

### 2.1 挖真实意图（Job-to-be-Done）

按 P1 把用户"想要"翻译成 Job：

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

### 2.2 收项目事实

按 P2 grep / read 实际文件，每条事实必须能引用到具体路径：

- 目录结构、模块边界、依赖方向
- 已有同类实现（grep 关键字 / 函数名 / 类名）
- 历史决策（git log、相关注释、已有方案）
- 数据模型、接口契约、错误处理风格、测试方式
- 用户偏好、禁区、长期目标

无项目事实引用 → 回此步，不允许进入推荐。

**改公开接口**（设计卡级别）按 P5 额外提供：

- 调用方 grep 结果（具体文件:行号 列表）
- 至少抽样 3 个调用方读其上下文，确认改动影响

### 2.3 决策驱动变量

按 P3 进入候选对比 / 切片清单 / 健康度评估之前，必须把"会改变最终推荐"的变量解决。详见 [clarifying-questions.md](references/clarifying-questions.md)。

逐变量分类：

- **driver（不可推断）** → 用 AskUserQuestion 工具问；优先多选，每个 description 写 implication；一次最多 4 题
- **driver（可推断）** → grep / read 项目代码 / git log / 已加载 memory，引用证据并标"待用户否决"
- **边角** → 标"假设"，不必问

先查再问的顺序：项目代码 → git log → memory → README → 查不到才问，避免重复打扰。

### 2.4 写 Goals / Non-Goals / 成功标准 / diff 预算

- **Goals**：可量化或可观察的成果（不是"提升体验"）
- **Non-Goals**：显式列出本次合理但不做的（防 AI 越界 / scope creep）
- **成功标准**：每个 Goal 对应可验证的现象 / 命令
- **输入 / 输出**：数据 / 接口 / 文件 / UI / 命令 / 副作用
- **约束**：技术栈 / 风格 / 性能 / 兼容
- **决策点**：哪些需要用户拍板
- **diff 预算**（方案卡 / 设计卡必填，对齐卡可选，按 P7）：预期改动文件数（量级，如 1-2 / 3-5 / 5-10）+ 预期改动行数（量级，如 <50 / 50-200 / 200+）；触及未列文件 → building 必须停下报告

关键缺口按 §2.3 分类处理：driver 类必须 AskUserQuestion 或引用项目事实；边角才可"假设"。

### 2.5 识别代码级约束（NFR-lite）

加载 [code-quality.md](references/code-quality.md)。逐项过 6 类约束（性能 / 并发 / 可维护 / 可靠 / 安全 / 兼容），命中项写：

- **约束**（具体场景）
- **检查方式**（可执行命令 / 可观察现象）

档位差：对齐卡通常 1-2 项；方案卡列 #1/#2 优先；设计卡完整覆盖。

### 2.6 子模式展开

按 §1.2 加载对应 reference 并执行：

- **design**：发散思路 → 2-3 候选 → Decision Drivers 评分（P4）→ 影响范围分类（P5）→ 推荐
- **large**：范围收敛 → **Walking Skeleton 第一刀** → 垂直切片 → 切片清单 → 进入 / 完成条件
- **deps**：联网查候选 → 健康度八维 → 项目适配 → 接入验证

设计卡级额外做 **S/B 拆分**（按 P8）：S 类（结构，不改行为）+ B 类（行为）两类，顺序 S → 测试 → B → 测试，各自一次 commit。

### 2.7 失败模式预判 + 验证映射

加载 [failure-modes.md](references/failure-modes.md)。按 P6 强制 code-level pre-mortem：

1. 假设 AI 按这个方案写完代码，最有可能哪里出 bug？
2. 写 ≥3 条具体失败模式（场景 + 原因 + 后果）
3. 每条对应一个可执行验证项（优先转 RED 测试）
4. High 级（崩溃 / 数据丢失 / 安全漏洞 / 公开接口破坏）必须有针对性测试

输出：失败模式 ↔ 验证项 表格。无映射 → 回此步。

### 2.8 中段自检

进入推荐前 checkbox 全过：

- [ ] 真实意图 / Non-Goals / 成功标准 已写出（P1）
- [ ] driver 变量已 asked 或 inferred-with-evidence（P3）
- [ ] 项目事实有具体路径引用（P2）
- [ ] 改公开接口时调用方 grep 已列（P5）
- [ ] 档位已选定且与规模匹配（§1.3）
- [ ] 方案卡 / 设计卡 含 diff 预算（P7）
- [ ] 代码级约束识别覆盖命中项
- [ ] 子模式 reference 已加载并执行
- [ ] large 含 Walking Skeleton 第一刀边界
- [ ] 设计卡 含 S/B 拆分顺序（P8）
- [ ] 失败模式 ≥3 条且每条有验证项（P6）
- [ ] 命中落盘触发条件时（§1.4）落盘路径已规划

任一未通过 → 回对应步骤，禁止前进。

### 2.9 收敛推荐

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

### 2.10 决策记录段（仅设计卡）

设计卡需要一段决策记录（不是 ADR governance，无状态流转 / supersede 链）：

- 标题 / 日期 / 上下文与问题 / Decision Drivers / 候选与权衡 / 决策结果 / 正负面后果 / 重评估条件

作用：给未来 AI / 人留个"为什么这么做"的小段，几十行内。

### 2.11 落盘 MD（命中即写）

按 §1.4 命中触发条件时，用 Write 工具落盘到 `docs/astra/<YYYY-MM-DD>-<slug>.md`，再交接 building：

```text
设计文档已落盘：<绝对路径>
building skill 开始实施时请以此文件为契约，触及 Non-Goals / 超 diff 预算 / 越切片边界 → 停下回 planning 重评估。
```

## 3. 质量门

### 3.1 推荐前硬阻断表（唯一完整声明）

输出推荐前任意一项命中 → 停下回对应步骤。下文 Final Gate 按编号引用，不复述：

| # | 硬阻断 | 触发信号 | 替代动作 |
|---|---|---|---|
| **H1** | "假设"绕过 driver | 输出含"假设：[driver 变量]=X"/"团队偏好不清楚先假设" | AskUserQuestion 问或引项目事实（P3） |
| **H2** | 项目事实无路径引用 | "已有同类实现"未带文件名 / "最佳实践是 X"无项目证据 | grep / read，给文件:函数（P2） |
| **H3** | 推荐"两者都行"/ 主观感觉 | "看团队偏好"/"看个人喜好"/"方案 A 更优雅" | 列 Decision Drivers 评分（P4） |
| **H4** | 改公开接口未 grep 调用方 | 设计卡级别无调用方列表 / "改一下函数签名应该没影响" | grep 调用方逐项（P5） |
| **H5** | 命中落盘条件未落盘 | 设计卡 / large / 大型方案卡只贴 markdown / "等会再补文档" | Write 工具落盘 docs/astra/...md（§1.4） |
| **H6** | 失败模式 + 验证不齐 | <3 条 / 无验证项 / "风险不大" / "应该没问题" | ≥3 条 + 每条对应验证（P6） |

### 3.2 Final Gate

输出前扫流程层级三件事（不重扫 H 表 / 禁止输出表，那是 §3.1 / §4 各自的事）。任一违规不得输出：

1. **扫推荐段**（§2.9）：含"为什么选它（逐 Driver）"+"为什么不选其他"+"影响范围"+"下一步实施边界"四件齐全
2. **扫子模式专属交付**：design 候选表 / large Walking Skeleton 完成标志 / deps 健康度八维 + 安装命令——按 reference 末尾"输出片段"对照
3. **扫落盘**（§1.4）：命中触发条件时回复里必须含已落盘 `docs/astra/<date>-<slug>.md` 的具体路径（H5）

## 4. 共用禁止输出

| 禁止 | 替代 |
|---|---|
| "先做简单版" / "后续可扩展" | 标明对齐卡 / Walking Skeleton；写后续切片 + 重评估条件 |
| "需求不明确所以没法设计" | 用 AskUserQuestion 问 driver；边角才出"假设版" |
| "性能没问题" / "代码质量没问题" | 写代码级约束 + 检查方式（§2.5） |
| "AI 写的时候自己注意" | 写明确检查项 + 验证命令 + diff 预算（P7） |
| "结构和功能一起改了" | 拆 S/B 两类，分别 commit（P8 + §2.6） |
| 同一需求拆"设计 + 评估"两份 | 合并到同一份 `docs/astra/<date>-<slug>.md`（§1.4） |

## 5. 输出骨架

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
