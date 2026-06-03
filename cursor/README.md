# Skills 总览

这套个人 Skills 按"工作模式"拆分。每个 Skill 必须有清晰触发条件、动作化流程、检查门、反逃逸规则和验证证据要求。

## 总原则

- **先路由再执行**：先判断任务类型，再加载对应 Skill，不把所有规则混成一坨。
- **先证据后结论**：读代码、查配置、跑命令、看 diff 之后再判断。
- **先契约后实现**：需求、布局、接口、行为、验证标准不清楚时，不进入编码。
- **完成必须可验证**：没有测试、构建、lint、运行时证据或明确未验证原因，不声称完成。
- **禁止半成品交付**：不写占位、临时兼容、只覆盖 happy path、默认值掩盖问题。
- **保护用户改动**：脏工作区内只处理当前任务相关变更，不回滚不相关改动。

## 任务规模分流

接到任务先按规模决定走多深的流程，不确定时往上走一档，绝不下降。

| 规模 | 触发条件 | 处理方式 |
|---|---|---|
| **Trivial** | 改字面量/文案/单个配置项；≤10 行；单文件；无逻辑分支变化；无新依赖；无 git 提交 | 跳过完整 Skill 仪式，直接执行并跑最小验证 |
| **Standard** | 单一目标、能在一两次交互内说清；跨 1-3 文件 | 按对应 Skill 强制流程跑完 |
| **Major** | 跨模块 / 跨阶段 / 行为契约不清 / 高风险 / 改公共 API / 改数据格式 | 先 `planning`，再切对应实施 Skill，必要时 worktree 隔离 |

## 路由顺序

按出现的关键词或意图选第一个命中的 Skill；可叠加多个。

1. `planning`：要方案/架构取舍/选型/拆解大需求/还没准备写代码。
2. `reading-code`：先读代码、梳理职责、调用链、数据流、影响范围。
3. `designing-frontend`：前端 UI、布局、组件、响应式、设计系统、前端架构。
4. `debugging`：报错、异常结果、回归、环境差异、偶发失败。
5. `refactoring`：重构、整理结构、抽公共逻辑，要求行为不变。
6. `building`：普通功能实现、写测试、改配置/feature flag/路径。
7. `reviewing-code`：review diff、PR、风险评估。
8. `git-safety`：提交、暂存、整理本地改动、脏工作区保护。
9. `verifying`：完成前验收，被上面多个 Skill 在验证步引用。
10. `engineering-skills`：新增/修改/审计 SKILL.md，含规范核对和设计模式落点。

## 常见组合

- 前端页面或组件：`designing-frontend` + `building` + `verifying`
- 前端方案或技术选型：`planning` + `designing-frontend`
- 新功能开发：`building` + `verifying`
- 新增三方件或替换依赖：`planning`(deps 子模式) + `building` + `verifying`
- 修 bug：`debugging` + `building`(test 子模式) + `verifying`
- 重构：`refactoring` + `verifying`
- 配置驱动改动：`building`(config 子模式) + `verifying`
- 改 X 前 X 周边乱：`building`(tidy 子模式) → `building`(feature 子模式)
- 大型需求：`planning`(large 子模式，含 Walking Skeleton + 切片清单) + 对应实施 Skill
- 提交前整理：`git-safety` + `verifying`
- 看不懂的代码：`reading-code` → 决定后续走哪个 Skill
- 写/改/审 skill：`engineering-skills`（new / revise / audit 子模式）

## Skill 列表

| Skill | 作用 | 子模式/要点 |
|---|---|---|
| `planning` | 方案/架构/选型/大需求拆解，产出可被 building 消费的执行卡 | design / large / deps；档位：对齐卡 / 方案卡 / 设计卡 |
| `reading-code` | 读代码、画职责、画调用链 | 职责/调用链/数据流/影响范围/大文件 |
| `designing-frontend` | 前端 UI/布局/组件/架构 | 布局契约优先于视觉装饰 |
| `debugging` | 从现象追根因再修 | 现象/触发/直接原因/根因/验证 |
| `refactoring` | 不改行为、降复杂度（跨文件 / 跨模块） | 行为签名 + 基线保护 + 小步 |
| `building` | 实现/写测试/改配置/就近 tidy；消费 planning 执行卡 | feature / test / config / tidy |
| `reviewing-code` | review diff/PR | 正确性/回归/数据/结构/安全/验证 |
| `git-safety` | 暂存/提交/PR/脏工作区 | 逐文件审查 + 敏感文件门 |
| `verifying` | 用证据证明完成 | 命令/结果/覆盖路径/未验证/风险 |
| `engineering-skills` | 写/改/审 SKILL.md | new / revise / audit；规范核对 + 5 模式落点 |

## Skill 质量标准

每个 `SKILL.md` 必须满足：

- frontmatter `name` 与目录名一致，`description` 用第三人称、含触发词、≤1024 字符。
- 正文 ≤500 行，包含 Core Principle、适用范围、强制流程、中段自检、Final Gate、禁止输出模式。
- 复杂知识放一层 `references/`，主文件保持可扫描。
- 规则必须动作化：不用"注意性能"，改成"检查哪些路径，用什么命令，失败怎么处理"。
- 输出要求必须可验证：具体命令、具体路径、具体对比方式。
- frontmatter 用英文，正文用中文。

## 新增 Skill 判断

只有同时满足以下条件才新建：

- 任务模式稳定且不同于现有 Skill。
- 触发词稳定，不会大量抢占现有 Skill。
- 输出结构稳定。
- 需要独立 reference 或检查门。

否则优先改现有 Skill 或加子模式。
