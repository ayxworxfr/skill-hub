---
name: building
description: Implements code changes (feature work, helper modules, scripts), writes tests for behavior coverage, applies config-driven changes (YAML/JSON/env/path/feature flag), or executes Tidy First structural cleanup. Consumes a planning execution card (alignment / solution / design) as task contract — reads existing patterns, follows diff budget, runs failure-mode-derived RED tests, splits structural vs behavioral commits, and verifies with evidence. Use when the user says "implement"/"add"/"write tests"/"补一下"/"改一下"/"按现有风格"/"加个 feature flag"/"先 tidy 一下"/"按计划开做", or wants ordinary feature work that is not mainly debugging, review, refactor-only, frontend design, git cleanup, or plan-only.
---

# Building（编码执行）

## Core Principle

把"做改动"收敛为可验证交付：消费 planning 执行卡作为任务契约，先读现有模式、做最小完整实现、用证据证明结果。

锚定原则（每条都是动词）：

- **消费 plan 卡**：有卡按卡执行，把卡里所有字段当硬约束，不二次设计
- **read-before-write**：grep / read 实际文件，找到现有同类实现再下笔
- **跑 RED→GREEN**（推荐 TDD）：失败模式表里 High 级先写失败测试，看到红再写绿
- **拆 S/B commit**（Tidy First）：结构改和行为改不在同一 commit
- **守 diff 预算**：触及未列文件即停下报告，不擅自扩
- **覆盖失败路径**：不允许 happy path only / try-catch 吞错 / silent default
- **硬阻断 AI 反模式**：hallucination / silent fake success / scope creep / over-engineering / inconsistent edit

## 子模式判定（先做这一步）

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| 实现 / 新增功能 / 补能力 / 改业务逻辑 / 写脚本 / 工具函数 | **feature** | （主文件 + writing-tests.md 若做 TDD） |
| 写测试 / 加回归 / 覆盖 X 行为 / 补单元测试 / 集成测试 | **test** | [writing-tests.md](references/writing-tests.md) |
| 改 YAML / JSON / env / feature flag / 路径 / 构建配置 / 模型 / provider | **config** | [config-changes.md](references/config-changes.md) |
| Tidy 一下 / 先整理结构 / 抽函数 / 改名 / 删 dead code（不改行为） | **tidy** | [tidy.md](references/tidy.md) |

一个任务可能跨多个子模式。**Tidy 必须先于 feature**，分别 commit。

## 适用范围

优先用于：

- 新增 / 修改业务逻辑、脚本、工具函数、模块能力
- 写新测试 / 为 bug 补回归测试 / 为重构建立行为保护
- 改字段名、模型名、provider、目录、文件格式、构建配置、feature flag
- 在 feature / fix 前做结构整理（抽函数 / 改名 / 删 dead code）

不要用于：

- 报错、异常结果、根因排查 → `debugging`
- 只要方案或架构取舍 → `planning`
- 只做行为不变的结构整理且**跨多文件 / 大重构** → `refactoring`
- 前端 UI / 布局 / 组件设计 → `designing-frontend`
- 代码审查 → `reviewing-code`
- 提交、push、PR → `git-safety`

## 任务规模判定（轻量通道）

满足全部条件可走 Trivial 直达执行，跳过完整流程仪式：

- 改动 ≤ 10 行
- 单文件、不跨模块
- 无逻辑分支变化（改字面量、改文案、加日志、调单个配置项）
- 无新依赖、无新接口、无新公共 API
- 不涉及敏感文件、不涉及 git 提交

否则按下面的强制流程走。**不确定时往上走一档，绝不下降。**

## 强制流程

### 1. 消费执行卡（如有）

planning 输出的执行卡是任务契约。building 不重复定义卡里有什么，按卡里**实际有的字段**执行：

- **有卡**：把每个字段当硬约束（Goals / Non-Goals / diff 预算 / 项目事实 / 调用方 grep / 失败模式 ↔ 验证 / S/B 顺序 / 切片入口与完成标志），不二次设计
- **无卡且任务跨多文件 / 改公开接口** → 回 `planning` skill 出卡再回来
- **无卡且 Trivial / 单一目标** → 进 Step 2 自填最小契约
- **越界即停**：触及 Non-Goals 或 diff 预算外文件 → 停下报告

字段细节以执行卡本身为准，本文件不重述。

### 2. 任务契约（无执行卡时自填最小段）

开始改动前写清：

- **目标**：要改变什么行为或新增什么能力
- **非目标**：明确不处理哪些相邻问题
- **输入 / 输出**：数据 / 参数 / 文件 / 接口 / 用户操作；返回值 / 文件 / UI / 状态 / 日志 / 副作用
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
| **over-engineering** | 加"未来扩展点" / 提前抽象 | 删；下一切片再加 |
| **inconsistent edit** | 改公开 API 未同步调用方 | grep 调用方逐项更新 |
| **happy path only** | 失败路径无显式处理 | 加显式分支或显式拒绝 |
| **修改测试让代码通过** | 改测试断言以适配新代码 | 反过来：先确认测试断言对，再改代码 |

### 5. 中段自检（第二层防御）

进入实施前确认：

- [ ] 已消费 plan 卡（如有），任务契约字段齐全
- [ ] 已读到现有模式（能引用具体文件:函数）
- [ ] 任务契约的关键分支都有对应实现路径
- [ ] 没有把任务实际是 bug / 重构 / 前端 / 配置的情况误判为 feature
- [ ] 已加载子模式对应 reference（test / config / tidy）
- [ ] diff 预算心里有数（越界会触发停下）

任一未通过 → 回 Step 1-3 补；如果发现归类错了，切换对应 skill。

### 6. 实施（按子模式）

#### 共用规则

- 跟随项目现有代码风格和目录结构
- 删除已失效旧逻辑，不注释保留废代码（保留有意义的现有注释）
- 不新增临时兼容、占位分支、默认值掩盖问题
- 不为未来假设做抽象
- 不顺手重构无关模块（要做 tidy → 先 tidy commit 再 feature commit）
- 不写占位函数、空分支、伪实现
- 新注释只解释不明显的业务约束或关键判断

#### 复杂度阈值（信号，不是硬上限）

命中 ≥1 项 → 看一眼是否要 tidy 子模式先做结构整理：

- 函数 > 20 行 / 嵌套 > 3 层 / 参数 > 4 个 / 单文件核心逻辑 > 100 行

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

锚定 Kent Beck Tidy First：S 类（Structural，tidy 子模式产物，不改 user-visible 行为）+ B 类（Behavioral，feature / test / config 产物）。

**顺序固定**：S → 跑测试通过 → B → 跑新测试通过。每类一次 commit。message 用 `tidy:` / `feat:` / `fix:` / `test:` / `config:` 区分。

设计卡级别 S/B 顺序由 plan 卡指定；building 按卡执行。

### 8. 验证

完成后必须按 `verifying` skill 选择最小有效验证：

- 失败模式表里 High 级 RED 测试现在变绿
- 相关单元测试 / 集成测试
- lint / typecheck / build
- 调用方 grep 列出的位置编译 / 类型检查通过
- 手动复现路径
- 文件 / 输出对比

无法验证时写清原因、已检查内容和剩余风险。

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

## Final Gate（第三层防御）

输出前对自己的回答执行扫描动作：

1. **扫"共用禁止输出"表第 1 列字面量**：每条字面量都不应在输出里出现；命中即回对应步骤改写
2. **扫"AI 反模式"7 类触发信号**：import/API/库存在性、try-catch、Non-Goals 越界、未同步调用方——逐项扫
3. **扫 plan 卡字段**：Goals / Non-Goals / diff 预算 / 失败模式 / 调用方 grep / S/B 顺序 / 切片完成标志——逐项核对自己的实现是否覆盖
4. **扫验证段**：每条验证写了具体命令 + 实际结果（不是"已运行"）；High 级失败模式有 RED→GREEN 证据
5. **扫 commit 拆分**：S 类 commit message 用 `tidy:`，B 类用 `feat/fix/test/config:`；S 在 B 之前
6. **按子模式扫专属字段**：test 的"测试覆盖输入/行为/预期"+ 人审标记；config 的"配置链路 + 缺省验证"；tidy 的"行为未变 + 测试前后绿"——按 reference 末尾"输出片段"对照

任一扫描发现违规不得声称完成。

## 输出骨架

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
