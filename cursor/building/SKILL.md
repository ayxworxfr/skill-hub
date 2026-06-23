---
name: building
description: Implements code changes, writes tests, applies config-driven changes (YAML/JSON/env/feature flag), or runs Tidy First structural cleanup. Use when the user says "implement"/"add"/"write tests"/"补一下"/"改一下"/"按现有风格"/"加个 feature flag"/"先 tidy 一下"/"按计划开做", or asks for ordinary feature work. Skip for:bug debugging, code review, refactor-only, frontend design, git operations, or plan-only requests.
---

# Building（编码执行）

## Core Principle

把"做改动"收敛为可验证交付：消费 planning 执行卡作为任务契约，先读现有模式、做最小完整实现、用证据证明结果。

锚定原则（**唯一完整声明**，下文按编号引用，不复述）：

- **P1 消费 plan 卡**：有卡按卡执行，所有字段当硬约束，不二次设计
- **P2 read-before-write**：grep / read 实际文件，找到现有同类实现再下笔
- **P3 跑 RED→GREEN**（推荐 TDD）：失败模式表里 High 级先写失败测试，看到红再写绿
- **P4 拆 S/B commit**（Tidy First）：结构改和行为改不在同一 commit
- **P5 守 diff 预算**：触及未列文件即停下报告，不擅自扩
- **P6 覆盖失败路径**：不允许 happy path only / try-catch 吞错 / silent default
- **P7 硬阻断 AI 反模式**：见 [§3.1 反模式硬阻断表](#31-反模式硬阻断表唯一完整声明)

## 术语小词典

外来术语首次出现位置一行兜底，避免跨 skill 漂移：

| 术语 | 定义 | 来源 |
|---|---|---|
| 对齐卡 / 方案卡 / 设计卡 | planning 三档产物，分别承载"问题/范围对齐"、"方案选择 + Decision Drivers"、"切片 + 失败模式" | [planning](../planning/SKILL.md) |
| Walking Skeleton | 跨全栈最薄的端到端可运行切片 | [planning](../planning/SKILL.md) |
| Decision Drivers | 选型时的硬约束维度（性能 / 团队熟悉度 / 兼容性等） | [planning](../planning/SKILL.md) |
| 失败模式表 | 设计卡里 High / Med / Low 三级失败枚举 + 对应验证 | [planning](../planning/SKILL.md) |
| S 类 / B 类 commit | Kent Beck Tidy First：Structural（不改 user-visible 行为） / Behavioral（改行为） | 本 skill §2.5 |
| RED→GREEN | TDD 红绿循环：先写失败测试见红，再写实现见绿 | 本 skill P3 |

## 1. 决策框架

入口决策表：先判规模，再判子模式，最后判并行。

### 1.1 是否走 building

| 任务类型 | 走哪 |
|---|---|
| 新增 / 修改业务逻辑、脚本、工具函数、模块能力 | building |
| 写新测试 / 为 bug 补回归 / 为重构建立行为保护 | building |
| 改字段名、模型名、provider、目录、文件格式、构建配置、feature flag | building |
| 在 feature / fix 前做结构整理（抽函数 / 改名 / 删 dead code） | building |
| 报错、异常结果、根因排查 | [debugging](../debugging/SKILL.md) |
| 只要方案或架构取舍 | [planning](../planning/SKILL.md) |
| 行为不变的结构整理且**跨多文件 / 大重构** | [refactoring](../refactoring/SKILL.md) |
| 前端 UI / 布局 / 组件设计 | [designing-frontend](../designing-frontend/SKILL.md) |
| 代码审查 | [reviewing-code](../reviewing-code/SKILL.md) |
| 提交、push、PR | [git-safety](../git-safety/SKILL.md) |

### 1.2 任务规模档位

满足**全部**条件可走 Trivial 直达，跳过 §2 完整流程：

- 改动 ≤ 10 行
- 单文件、不跨模块
- 无逻辑分支变化（改字面量、改文案、加日志、调单个配置项）
- 无新依赖、无新接口、无新公共 API
- 不涉及敏感文件、不涉及 git 提交

否则进 §2。**不确定时往上走一档，绝不下降。**

### 1.3 子模式判定

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| 实现 / 新增功能 / 补能力 / 改业务逻辑 / 写脚本 / 工具函数 | **feature** | （主文件，TDD 时叠加 writing-tests.md） |
| 写测试 / 加回归 / 覆盖 X 行为 / 补单元测试 / 集成测试 | **test** | [writing-tests.md](references/writing-tests.md) |
| 改 YAML / JSON / env / feature flag / 路径 / 构建配置 / 模型 / provider | **config** | [config-changes.md](references/config-changes.md) |
| Tidy 一下 / 先整理结构 / 抽函数 / 改名 / 删 dead code（不改行为） | **tidy** | [tidy.md](references/tidy.md) |

一个任务可能跨多个子模式。**Tidy 必须先于 feature**，分别 commit（P4）。

### 1.4 并行模式判定

满足**全部**条件时，编码前用 AskUserQuestion 询问是否启用多 agent 并行：

- 执行卡或任务契约含 ≥2 个相互独立的切片 / 文件 / 模块（无强顺序依赖）
- diff 预算 > 100 行 或 > 3 文件
- 不在 Trivial 通道

询问内容：

- header：编码模式
- 问：检测到 N 个独立单元（具体列出每个单元做什么），是否启用多 agent 并行编码？
- 选项 A "并行（推荐）"：N 个单元 dispatch 到 N 个子 agent 同时实施，整体耗时显著缩短
- 选项 B "串行"：单 agent 顺序实施，便于调试与单元互参考

不询问（直接走串行）的场景：

- Trivial / 单文件 / 单函数改动
- 单元间存在强依赖（B 必须等 A 落地才能写）
- 用户已明确表态（"按串行做" / "你直接并行"）
- 设计卡 S/B 顺序里 S 必须先于 B → S 阶段不并行，B 阶段内独立切片可问

并行执行时：每个子 agent 拿到自己的单元契约（Goals / Non-Goals / 涉及文件 / 验证标准）独立执行；主 agent 合并 diff、跑统一验证、处理子 agent 越界 / 冲突、按 P4 顺序提交。子 agent 完成回收后仍要走 §2.5 commit 拆分 + §2.6 验证。

## 2. 执行流程

### 2.1 建立任务契约

planning 输出的执行卡是任务契约。按 P1：

- **有卡**：把每个字段当硬约束（Goals / Non-Goals / diff 预算 / 项目事实 / 调用方 grep / 失败模式 ↔ 验证 / S/B 顺序 / 切片入口与完成标志），不二次设计
- **无卡且任务跨多文件 / 改公开接口** → 回 planning 出卡再回来
- **无卡且 Trivial / 单一目标** → 自填最小契约 5 字段：目标 / 非目标 / 输入输出 / diff 预算 / 验收

字段细节以执行卡本身为准，本文件不重述。

### 2.2 读取现有模式

按 P2 至少检查：

- 入口文件和直接调用方
- 被改逻辑的上下游数据流
- 相邻测试、配置、类型定义、错误处理方式
- 项目已有同类实现、命名、目录、工具函数
- import / API / 库的来源（package.json / requirements.txt / go.mod 等 lockfile）

### 2.3 中段自检

进入实施前 checkbox 全过：

- [ ] 已消费 plan 卡（如有），任务契约字段齐全（P1）
- [ ] 已读到现有模式，能引用具体 文件:函数（P2）
- [ ] 任务契约的关键分支都有对应实现路径
- [ ] 没有把任务实际是 bug / 重构 / 前端 / 配置的情况误判为 feature
- [ ] 已加载子模式对应 reference（按 §1.3）
- [ ] diff 预算心里有数（P5）

任一未通过 → 回 §2.1-2.2 补；归类错了切对应 skill。

### 2.4 实施

按 §1.3 子模式 + §1.4 并行决策执行。

共用规则：

- 跟随项目现有代码风格和目录结构
- 删除已失效旧逻辑，不注释保留废代码（保留有意义的现有注释）
- 不新增临时兼容、占位分支、默认值掩盖问题
- 不为未来假设做抽象
- 不顺手重构无关模块（要做 tidy → 先 tidy commit 再 feature commit）
- 不写占位函数、空分支、伪实现
- 新注释只解释不明显的业务约束或关键判断

复杂度信号（命中 ≥1 项 → 看是否要先走 tidy 子模式）：函数 > 20 行 / 嵌套 > 3 层 / 参数 > 4 个 / 单文件核心逻辑 > 100 行。判断：是新功能堆出来的复杂度（→ 切片）还是历史欠账（→ tidy 先）。

feature 子模式额外约束（test / config / tidy 见对应 reference）：

- 加载 [code-craftsmanship.md](references/code-craftsmanship.md)，对照欠抽象（U）/ 过抽象（O）双向信号，判断顺序走完
- 覆盖任务契约里的全部关键分支（P6）
- 失败模式表中 High 级**先写 RED 测试**（P3）
- 失败路径有显式处理（P6）
- 边界条件（空、null、空集合、超大、并发、时序）显式处理或显式拒绝
- 调用方 grep 列出的位置改完后**逐项验证**

### 2.5 拆 S/B commit

按 P4：S 类（Structural，tidy 子模式产物，不改 user-visible 行为）+ B 类（Behavioral，feature / test / config 产物）。

**顺序固定**：S → 跑测试通过 → B → 跑新测试通过。每类一次 commit。message 用 `tidy:` / `feat:` / `fix:` / `test:` / `config:` 区分。

设计卡级 S/B 顺序由 plan 卡指定；building 按卡执行。

### 2.6 验证

按 [verifying](../verifying/SKILL.md) 选最小有效验证：

- 失败模式表里 High 级 RED 测试现在变绿（P3）
- 相关单元测试 / 集成测试
- lint / typecheck / build
- 调用方 grep 列出的位置编译 / 类型检查通过
- 手动复现路径
- 文件 / 输出对比

无法验证时写清原因、已检查内容和剩余风险。

## 3. 质量门

### 3.1 反模式硬阻断表（唯一完整声明）

实施过程任意一项命中 → 停下重做。下文 Final Gate 按编号引用，不复述：

| # | 反模式 | 触发信号 | 替代动作 |
|---|---|---|---|
| **R1** | hallucination | import / API / 库不存在 | grep lockfile / 实际安装；找不到则停下问 |
| **R2** | silent fake success | try-catch 吞错 / silent default / return None 掩盖 | 显式抛错 / 显式 None 校验（P6） |
| **R3** | scope creep | 触及 diff 预算外文件 / Non-Goals 里的事 | 停下报告，不擅自扩（P5） |
| **R4** | over-engineering | 加"未来扩展点" / 提前抽象 | 删；下一切片再加 |
| **R5** | inconsistent edit | 改公开 API 未同步调用方 | grep 调用方逐项更新 |
| **R6** | happy path only | 失败路径无显式处理 | 加显式分支或显式拒绝（P6） |
| **R7** | 修改测试让代码通过 | 改测试断言以适配新代码 | 反过来：先确认测试断言对，再改代码 |

### 3.2 Final Gate

输出前扫流程层级三件事（不重扫 R 表 / 禁止输出表，那是 §3.1 / §4 各自的事）。任一违规不得声称完成：

1. **扫 plan 卡字段覆盖**（§2.1 + §2.5）：Goals / Non-Goals / diff 预算 / 失败模式 / 调用方 grep / S/B 顺序（含 commit message 前缀 `tidy:` 在 `feat / fix / test / config:` 前）/ 切片完成标志，逐项核对实现是否覆盖；含子模式专属字段（test / config / tidy reference 末尾"输出片段"）
2. **扫验证段**（§2.6）：每条验证写了具体命令 + 实际结果（不是"已运行"）；High 级失败模式有 RED→GREEN 证据
3. **扫并行决策**（§1.4）：满足触发条件时回复里必须能找到用户对并行 / 串行的明确选择；缺即违规

## 4. 共用禁止输出

| 禁止输出 | 替代动作 |
|---|---|
| "先做一个简单版" / "常见场景可以用了" | 交付完整实现，或明确说明阻塞缺口；对照验收列出覆盖和未覆盖路径 |
| "其他保持不变" / "应该没问题" | 明确列出未修改范围（让 diff 自证）+ 给验证命令 + 实际结果 |
| "这里加个兜底" | 追溯为什么数据 / 状态会异常并修根因（R2） |
| "AI 自己看着办" | 检查项 + 验证命令明确写出 |
| "结构和功能一起改" | 拆 S/B：先 tidy commit 再 feature commit（P4 + §2.5） |
| "我直接并行帮你做了" / "全部串行最稳" | 按 §1.4 询问，把选择权交用户 |

子模式独有禁止输出见对应 reference。

## 5. 输出骨架

```markdown
## 子模式
- <feature / test / config / tidy，多选时按出现顺序>

## 任务契约
- 来自执行卡：<对齐卡 / 方案卡 / 设计卡 / 切片 ID>，或自写
- 目标 / 非目标 / 输入 / 输出 / 验收：
- diff 预算：<文件数> / <行数>

## 实施
- 改了什么行为：
- 复用的项目模式：<具体文件:函数>
- 删除 / 适配的旧逻辑：
- 调用方 grep 验证（公开接口）：

## 失败模式与 RED 测试
- 引用失败模式表：F-1, F-3
- 写了哪些 RED 测试 + 现在状态：绿 / 仍红（说明）

## commit 拆分
- S 类（tidy）：commit 1, 2 ...
- B 类（feat / fix / config）：commit 3, 4 ...

## 验证
- 已运行：<命令>
- 结果：
- 覆盖路径 / 未验证：

## 残留
- <未验证项 / 越界检测 / 风险；没有写"无"是逃逸>
```

子模式追加片段：test / config / tidy 各自见对应 reference 末尾"输出片段"。feature 无独立追加。

不能省的核心字段：任务契约、实施（行为变更 + 复用模式引用 + 调用方 grep 验证）、验证（具体命令 + 结果）、残留。
