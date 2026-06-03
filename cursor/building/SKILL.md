---
name: building
description: Implements code changes (feature work, helper modules, scripts), writes tests for behavior coverage, applies config-driven changes (YAML/JSON/env/path/feature flag), or executes Tidy First structural cleanup. Consumes a planning execution card (alignment / solution / design) as task contract — reads existing patterns, follows diff budget, runs failure-mode-derived RED tests, splits structural vs behavioral commits, and verifies with evidence. Use when the user says "implement"/"add"/"write tests"/"补一下"/"改一下"/"按现有风格"/"加个 feature flag"/"先 tidy 一下"/"按计划开做", or wants ordinary feature work that is not mainly debugging, review, refactor-only, frontend design, git cleanup, or plan-only.
---

# Building（编码执行）

## Core Principle

把"做改动"收敛为可验证交付：消费 planning 执行卡作为任务契约，先读现有模式、做最小完整实现、用证据证明结果。

锚定原则：

- **plan 卡先消费**：有执行卡就按卡执行，不二次设计
- **read-before-write**：grep / read 实际文件，找到现有同类实现再下笔
- **TDD 红绿（推荐）**：失败模式表里的 High 级先写 RED 测试，看到失败再实现绿
- **结构改 vs 行为改 拆分（Tidy First）**：S 类和 B 类不同 commit
- **diff 预算 → 越界即停**：触及未列文件 → 停下报告，不擅自扩范围
- **失败路径显式覆盖**：不允许 happy path only / try-catch 吞错 / silent default
- **AI 反模式硬阻断**：hallucination / silent fake success / scope creep / over-engineering

**禁止偷懒**：

- "先简单版" / "happy path 够用" / "其他保持不变" / "应该没问题"
- 修改测试让代码通过（应反向）
- try-catch 吞异常掩盖根因
- 顺手重构无关模块
- 凭通用经验实现，跳过项目模式

## 子模式判定（先做这一步）

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| 实现 / 新增功能 / 补能力 / 改业务逻辑 / 写脚本 / 工具函数 | **feature** | （主文件 + failure-tests-tdd.md 若做 TDD） |
| 写测试 / 加回归 / 覆盖 X 行为 / 补单元测试 / 集成测试 | **test** | [writing-tests.md](references/writing-tests.md) |
| 改 YAML / JSON / env / feature flag / 路径 / 构建配置 / 模型 / provider | **config** | [config-changes.md](references/config-changes.md) |
| Tidy 一下 / 先整理结构 / 抽函数 / 改名 / 删 dead code（不改行为） | **tidy** | [tidy.md](references/tidy.md) |

一个任务可能跨多个子模式（如"实现 X 并加测试"，或"先 tidy 再加新行为"）。**Tidy 必须先于 feature**，分别 commit。

## 适用范围

优先用于：

- 新增或修改业务逻辑、脚本、工具函数、模块能力
- 写新测试、为 bug 补回归测试、为重构建立行为保护
- 改字段名、模型名、provider、目录、文件格式、构建配置、feature flag
- 在 feature / fix 前做结构整理（抽函数 / 改名 / 删 dead code）
- 用户说"实现" / "改一下" / "补上这个能力" / "按现有风格改" / "按计划开做"

不要用于：

- 报错、异常结果、根因排查：用 `debugging`
- 只要方案或架构取舍：用 `planning`
- 只做行为不变的结构整理且**跨多文件 / 大重构**：用 `refactoring`
- 前端 UI、布局、组件设计：用 `designing-frontend`
- 代码审查：用 `reviewing-code`
- 提交、push、PR：用 `git-safety`

## 任务规模判定（轻量通道）

满足全部条件可走 Trivial 直达执行，跳过完整流程仪式：

- 改动 ≤ 10 行
- 单文件、不跨模块
- 无逻辑分支变化（改字面量、改文案、加日志、调单个配置项）
- 无新依赖、无新接口、无新公共 API
- 不涉及敏感文件、不涉及 git 提交

否则按下面的强制流程走。**不确定时往上走一档，绝不下降。**

## 强制流程（共用骨架）

### 1. 消费 planning 执行卡（如有）

如果 planning skill 产出了执行卡（对齐卡 / 方案卡 / 设计卡），从中读出任务契约：

| plan 卡字段 | building 怎么用 |
|---|---|
| Goals + 成功标准 | 任务契约的目标 + 验收 |
| Non-Goals | 不做清单（越界即停依据） |
| 项目事实引用 | 必读基线（先读这些文件） |
| 调用方 grep（设计卡） | 改完后逐项验证调用方 |
| 命中代码级约束 | 实现时必须满足；验证时必查 |
| 失败模式 ↔ 验证表 | TDD 红测试来源 + Final Gate 必检项 |
| diff 预算 | 越界即停硬指标 |
| S/B 拆分顺序（设计卡） | commit 顺序 |
| 切片入口 / 完成标志（large） | 启动前提 + 完成判定 |

无执行卡时**先评估是否需要 planning**：跨多文件 / 多步骤 / 改公开接口 → 回 planning skill 出卡再回来。

### 2. 任务契约（无执行卡时自己写）

开始改动前写清：

- **目标**：要改变什么行为或新增什么能力
- **非目标**：明确不处理哪些相邻问题
- **输入**：数据、参数、文件、接口、用户操作
- **输出**：返回值、文件、UI、状态、日志、副作用
- **diff 预算**：预期改动文件数 + 行数（量级）
- **验收**：用什么命令、测试、对比或手动路径证明完成

缺少会影响实现判断的关键约束时，先补齐；不要边写边猜。

### 3. 读取现有模式（read-before-write）

至少检查：

- 入口文件和直接调用方
- 被改逻辑的上下游数据流
- 相邻测试、配置、类型定义、错误处理方式
- 项目已有同类实现、命名、目录、工具函数
- import / API / 库的来源（package.json / requirements.txt / go.mod 等 lockfile）

**禁止**：

- 只看一个函数就改公共行为
- 凭通用经验实现，跳过项目模式
- 引入项目未装的 import / 库（防 hallucination）

### 4. AI 反模式硬阻断

实施过程中任意一项命中 → 停下重做：

| 反模式 | 触发信号 | 处理 |
|---|---|---|
| **hallucination** | import / API / 库不存在 | grep lockfile / 实际安装；找不到则停下问 |
| **silent fake success** | try-catch 吞错 / silent default / return None 掩盖 | 改成显式抛错 / 显式 None 校验 |
| **scope creep** | 触及 diff 预算外文件 / Non-Goals 里的事 | 停下报告，不擅自扩 |
| **over-engineering** | 加"未来扩展点" / 抽提前抽象 | 删；下一切片再加 |
| **inconsistent edit** | 改公开 API 未同步调用方 | grep 调用方逐项更新 |
| **happy path only** | 失败路径无显式处理 | 加显式分支或显式拒绝 |
| **修改测试让代码通过** | 改测试断言以适配新代码 | 反过来：先确认测试断言对，再改代码 |

### 5. 中段自检

进入实施前确认：

- [ ] 已消费 plan 卡（如有），任务契约字段齐全
- [ ] 已读到现有模式（能引用具体文件:函数）
- [ ] 任务契约的关键分支都有对应实现路径
- [ ] 没有把任务实际是 bug / 重构 / 前端 / 配置的情况误判为 feature
- [ ] 已加载子模式对应 reference（test / config / tidy）
- [ ] diff 预算心里有数（越界会触发停下）

任一未通过 → 回 Step 1-3 补；如果发现归类错了，切换对应 Skill。

### 6. 实施（按子模式）

#### 共用规则

- 跟随项目现有代码风格和目录结构
- 删除已失效旧逻辑，不注释保留废代码
- 不新增临时兼容、占位分支、默认值掩盖问题
- 不为未来假设做抽象
- 不顺手重构无关模块（要做 tidy → 先 tidy commit 再 feature commit）
- 不写占位函数、空分支、伪实现
- 新注释只解释不明显的业务约束或关键判断

#### 复杂度阈值（Sandi Metz adapted）

下面是**信号阈值**，不是硬上限。命中 ≥1 项 → 看一眼是否要 tidy 子模式先做结构整理：

- 函数 > 20 行
- 嵌套 > 3 层
- 参数 > 4 个（含 options 字典展开后字段）
- 单文件类 / 模块 > 100 行的核心逻辑

命中后判断：是新功能堆出来的复杂度（→ 想想能不能切片）还是历史欠账（→ tidy 先）。

#### feature 子模式

- 覆盖任务契约里的全部关键分支（不只是 happy path）
- 失败模式表中 High 级**先写 RED 测试**（推荐 TDD 红绿）
- 失败路径有明确处理（不用 try-catch 吞异常）
- 边界条件（空、null、空集合、超大、并发、时序）显式处理或显式拒绝
- 调用方 grep 列出的位置改完后**逐项验证**

#### test / config / tidy 子模式

按对应 reference 执行：

- [writing-tests.md](references/writing-tests.md)
- [config-changes.md](references/config-changes.md)
- [tidy.md](references/tidy.md)

### 7. commit 拆分（S/B）

锚定 Kent Beck Tidy First：

- **S 类**（Structural）：tidy 子模式产物；不改 user-visible 行为；现有测试保持绿
- **B 类**（Behavioral）：feature / test / config 产物；可能加新测试

**顺序固定**：S → 跑测试通过 → B → 跑新测试通过

每类一次 commit。message 用 `tidy:` / `feat:` / `fix:` / `test:` / `config:` 区分。

### 8. 验证

完成后必须按 `verifying` skill 选择最小有效验证：

- 失败模式表里 High 级 RED 测试现在变绿
- 相关单元测试 / 集成测试
- lint / typecheck
- build
- 调用方 grep 列出的位置编译 / 类型检查通过
- 手动复现路径
- 文件 / 输出对比

无法验证时写清原因、已检查内容和剩余风险。

## Final Gate

输出前确认：

- [ ] 子模式判定正确（feature / test / config / tidy）
- [ ] 已加载并执行子模式 reference
- [ ] 已消费 plan 卡（若有）
- [ ] 已读现有模式而不是凭通用经验
- [ ] AI 反模式 7 类都未命中（或命中已修）
- [ ] 已覆盖主要输入、输出、失败路径、边界条件
- [ ] 失败模式表 High 级有对应 RED 测试且已变绿
- [ ] 调用方 grep 列出的位置已逐项验证（公开接口）
- [ ] diff 预算未超（超了 → 停下报告）
- [ ] S 类与 B 类已分别 commit
- [ ] 已删除或适配过时逻辑
- [ ] 已运行最小相关验证或明确说明无法验证
- [ ] 没有触发"禁止输出模式"任一行
- [ ] config：配置链路从源到使用方都已验证；测试 fixture 和文档同步
- [ ] test：断言外部可观察结果，没复制实现逻辑
- [ ] tidy：现有测试保持绿；commit message 标 `tidy:`

任一未通过不得声称完成。

## 共用检查门

未满足以下条件不得声称完成：

- feature：覆盖主要输入、输出、失败路径、边界条件，已读现有模式，已运行最小验证；High 级失败模式有 RED 测试
- test：见 [writing-tests.md](references/writing-tests.md) 检查门
- config：见 [config-changes.md](references/config-changes.md) 检查门
- tidy：见 [tidy.md](references/tidy.md) 检查门
- 触及 diff 预算外文件 → 停下报告，不擅自扩

## 共用禁止输出

| 禁止输出 | 替代动作 |
|---|---|
| "先做一个简单版" | 交付完整实现，或明确说明阻塞缺口 |
| "常见场景可以用了" | 对照验收标准列出覆盖和未覆盖路径 |
| "其他保持不变" | 明确列出未修改范围或让 diff 自证 |
| "应该没问题" | 给出验证命令、结果和剩余风险 |
| "这里加个兜底" | 追溯为什么数据 / 状态会异常并修根因 |
| "改测试让它过" | 反过来；除非测试断言本身是错的 |
| "顺手把 X 也改了" | 拆出来：要么单独 commit，要么放下个任务 |
| "AI 自己看着办" | 检查项 + 验证命令明确写出 |
| "结构和功能一起改" | 拆 S/B；先 tidy commit 再 feature commit |

子模式独有禁止输出见对应 reference。

## 输出骨架

完整骨架 + 子模式追加片段映射见 [output-skeleton.md](references/output-skeleton.md)。

主章节顺序：子模式 → 任务契约 → 实施 → 失败模式与 RED 测试 → commit 拆分 → 验证 → 残留。

子模式专属片段按各自 reference 追加。

## 参考来源

- Kent Beck, *Tidy First?* (O'Reilly 2023)
- Sandi Metz, "POODR Rules"（阈值适配 AI 编程）
- Simon Willison, "Red/Green TDD for Coding Agents" (2025)
- USENIX 2025 — Package Hallucinations 研究
