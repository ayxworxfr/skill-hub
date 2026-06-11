# Cursor / Claude Code Skills 集合

一套面向 AI 编程协作的个人 Skill 集合。每个 Skill 把一种工作模式（规划 / 实现 / 调试 / 审阅 …）固化成可触发的流程，配合检查门和验证证据要求，把 AI 的"看似在做"变成"做完且可验证"。

按 [Anthropic Agent Skills](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) 规范组织，可在 Cursor、Claude Code 及任何兼容 Skills 标准的 AI 客户端使用。

## 这套 Skill 解决什么问题

AI 写代码常见的失败模式：

- **没对齐就动手**：跳过需求 / 接口 / 验证标准的契约，直接写
- **症状层修补**：报错改 try-catch / 用默认值掩盖，不追根因
- **半成品**："先把基础做完再说"、留 TODO、只覆盖 happy path
- **声称完成无证据**：没跑测试、没看 diff 就说"做完了"
- **越权改动**：脏工作区里顺手回滚不相关改动

每个 Skill 针对一类典型场景，强制流程 + 检查门 + 禁止输出模式三件套，把上述失败模式从概率空间里移除。

## 设计哲学

### 1. 概率空间地形改造

LLM 不在"遵守"规则，是在概率空间选下一个 token。Skill 设计的本质 = 让正确路径变下坡，让错误路径变高墙。

### 2. 五个核心设计模式

| 模式 | 作用 |
|---|---|
| **动作化** | 用动词起手（搜索 / 列出 / 检查 / 统计），不写"注意 X" |
| **检查门** | 规则 + 检测动作 + 阻断条件，三件齐全才有约束力 |
| **三层防御** | Core Principle（开头）+ 流程内自检（中段）+ Final Gate（结尾） |
| **堵死逃逸** | 禁止输出表，列出 AI 高频借口（"应该没问题" / "可以根据需要扩展"）+ 替代动作 |
| **渐进披露** | 主 SKILL.md 保持可扫描，细则进 `references/` 按需加载 |

### 3. 总原则

- **先路由再执行**：先判断任务类型，加载对应 Skill，不把所有规则混成一坨
- **先证据后结论**：读代码、查配置、跑命令、看 diff 之后再判断
- **先契约后实现**：需求、接口、行为、验证标准不清楚时，不进入编码
- **完成必须可验证**：测试、构建、lint、运行时证据，或显式说"未验证"
- **禁止半成品交付**：不写占位、临时兼容、只覆盖 happy path、用默认值掩盖
- **保护用户改动**：脏工作区只动当前任务相关的改动

## Skill 列表

### 规划与决策

| Skill | 用途 | 子模式 |
|---|---|---|
| `planning` | 方案 / 架构 / 选型 / 大需求拆解，产出可被实施环节消费的"执行卡" | design（方案对比）/ large（Walking Skeleton + 垂直切片）/ deps（三方依赖评估） |
| `reading-code` | 读代码、梳理职责、调用链、数据流、影响范围 | — |

### 实施与质量

| Skill | 用途 | 子模式 |
|---|---|---|
| `building` | 实现功能 / 写测试 / 改配置 / 就近 Tidy | feature / test / config / tidy |
| `designing-frontend` | 前端 UI / 布局 / 组件 / 设计系统；布局契约优先于视觉装饰 | — |
| `refactoring` | 跨文件 / 跨模块结构改造，行为签名 + 基线保护 + 小步推进 | — |
| `debugging` | 从现象追根因再修，禁止症状层修补 | — |

### 审阅与交付

| Skill | 用途 | 子模式 |
|---|---|---|
| `reviewing-code` | review diff / PR / 暂存改动，输出 Critical / Major / Minor 证据 | — |
| `git-safety` | 暂存 / 提交 / PR / 脏工作区，逐文件审查 + 敏感文件门 + 危险操作授权 | — |
| `verifying` | 完成前用证据证明：命令 / 结果 / 覆盖路径 / 未验证项 / 风险 | — |

### 元能力

| Skill | 用途 | 子模式 |
|---|---|---|
| `engineering-skills` | 写 / 改 / 审 SKILL.md 本身，规范核对 + 5 模式落点 + 文件预算 | new / revise / audit |

## 任务规模分流

| 规模 | 触发条件 | 处理 |
|---|---|---|
| **Trivial** | 改字面量 / 文案 / 单配置项；≤10 行；单文件；无逻辑分支变化；无新依赖 | 跳过完整 Skill 仪式，直接做 + 跑最小验证 |
| **Standard** | 单一目标；跨 1-3 文件 | 按对应 Skill 强制流程跑完 |
| **Major** | 跨模块 / 跨阶段 / 行为契约不清 / 高风险 / 改公共 API / 改数据格式 | 先 `planning`，再切对应实施 Skill |

不确定时往上走一档，绝不下降。

## 路由（命中第一个匹配项）

1. `planning` — 要方案 / 取舍 / 选型 / 拆解大需求 / 还没准备写代码
2. `reading-code` — 先读代码、梳理职责 / 调用链 / 数据流
3. `designing-frontend` — 前端 UI / 布局 / 组件 / 设计系统
4. `debugging` — 报错 / 异常结果 / 回归 / 偶发失败
5. `refactoring` — 重构 / 整理结构 / 抽公共逻辑（行为不变）
6. `building` — 普通功能实现 / 写测试 / 改配置
7. `reviewing-code` — review diff / PR / 风险评估
8. `git-safety` — 提交 / 暂存 / 整理本地改动
9. `verifying` — 完成前验收
10. `engineering-skills` — 新增 / 修改 / 审计 SKILL.md

## 常见组合

| 场景 | Skill 组合 |
|---|---|
| 新功能开发 | `building` + `verifying` |
| 修 bug | `debugging` + `building`(test) + `verifying` |
| 前端页面 | `designing-frontend` + `building` + `verifying` |
| 前端方案 / 选型 | `planning` + `designing-frontend` |
| 新增三方件 | `planning`(deps) + `building` + `verifying` |
| 重构 | `refactoring` + `verifying` |
| 配置驱动改动 | `building`(config) + `verifying` |
| 改 X 前 X 周边乱 | `building`(tidy) → `building`(feature) |
| 大型需求 | `planning`(large，Walking Skeleton + 切片) + 对应实施 Skill |
| 提交前整理 | `git-safety` + `verifying` |
| 看不懂的代码 | `reading-code` → 决定后续走哪 |
| 写 / 改 / 审 skill | `engineering-skills`（new / revise / audit） |

## planning ↔ 实施 的协作模式

`planning` 输出的"执行卡"是后续实施环节的输入契约：

- **planning 决定**："做什么 / 为什么"——意图、Goals/Non-Goals、候选对比、影响范围、diff 预算、失败模式与验证、调用方 grep（设计卡）、S/B 拆分顺序、切片入口与完成标志（large）
- **实施环节决定**："怎么写 / 怎么验"——按卡里**实际有的字段**执行，不二次设计
- **越界即停**：实施环节触及 Non-Goals 或预算外文件 → 停下报告，回 planning 重评估

两个 Skill 通过卡上的字段衔接，互不知道对方内部流程。

## 目录结构

```
.cursor/
├── README.md          # 本文件，对外介绍 + 路由
├── planning/
│   ├── SKILL.md
│   └── references/    # 按需加载的细则
├── building/
│   ├── SKILL.md
│   └── references/
├── git-safety/
│   ├── SKILL.md
│   ├── references/
│   └── scripts/       # 危险操作硬阻断（pre-commit hook）
└── ...（其它 Skill）
```

每个 Skill 自包含：主文件 + 一层 `references/`（不嵌套）+ 可选 `scripts/` / `assets/`。Skill 之间不互相 import 文件。

## Skill 质量标准

每个 SKILL.md 必须满足：

- frontmatter `name` 与目录名一致，动名词形式（`processing-X`、`writing-Y`）
- `description` ≤1024 字符，第三人称，含触发短语（USE WHEN 模式或具体触发短语）
- 正文 ≤500 行（目标 ≤300），包含 Core Principle / 适用范围 / 强制流程 / Final Gate / 禁止输出表
- 复杂知识放一层 `references/`，主文件保持可扫描
- 规则必须动作化：不用"注意性能"，改成"找循环 → 检查嵌套 → 标记 O(n²) 以上点"
- 输出要求必须可验证：具体命令、具体路径、具体对比方式
- frontmatter 用英文，正文用中文

详细规范在 `engineering-skills/` 内。

## 安装

### 一键安装（推荐）

通过 `npx` 从仓库直接拉取并平铺到 skill 目录（每个 skill 独立目录，不嵌套在 `skill-hub/` 之下）。

```bash
# Claude Code · 用户级（默认）→ ~/.claude/skills/<skill>/
npx -y --package=git+ssh://git@gitlab.futunn.com:graycenzheng/skill-hub.git skill-hub

# Claude Code · 项目级 → <cwd>/.claude/skills/<skill>/
npx -y --package=git+ssh://git@gitlab.futunn.com:graycenzheng/skill-hub.git skill-hub --project

# Cursor · 用户级 → ~/.cursor/skills/<skill>/
npx -y --package=git+ssh://git@gitlab.futunn.com:graycenzheng/skill-hub.git skill-hub --cursor

# Cursor · 项目级 → <cwd>/.cursor/skills/<skill>/
npx -y --package=git+ssh://git@gitlab.futunn.com:graycenzheng/skill-hub.git skill-hub --cursor --project

# 已存在同名目录时强制覆盖
... skill-hub --force
```

参数：

| 参数 | 作用 |
|---|---|
| 默认 | 写入用户级 Claude 目录 |
| `--project` | 改写到当前工作目录 |
| `--cursor` | 改写到 `.cursor/skills/` 而非 `.claude/skills/` |
| `--force` | 覆盖已存在同名 skill 目录（默认遇冲突跳过） |

升级：直接重跑同一条 `npx` 命令（加 `--force` 覆盖旧版本）。

私有库注意：默认走 `git+ssh`，需本地配好 GitLab SSH key；要走 HTTPS + token 时改成 `git+https://gitlab.futunn.com/graycenzheng/skill-hub.git`。

### 手动安装

把目录复制到目标位置：

- Claude Code：`~/.claude/skills/` 或项目内 `.claude/skills/`
- Cursor：`~/.cursor/skills/` 或项目内 `.cursor/skills/`
- 其他 AI 客户端：只要支持 Anthropic Agent Skills 标准（`SKILL.md` + frontmatter `name` + `description`）即可

## 新增 / 修改 Skill

需要新加 Skill 时，触发 `engineering-skills`（new 子模式）。它会强制按 [Anthropic 官方规范](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) + 5 个设计模式落点 + 文件预算先行的流程产出。

只在同时满足以下条件时才新建 Skill：

- 任务模式稳定且与现有 Skill 不同
- 触发词稳定，不会大量抢占现有 Skill
- 输出结构稳定
- 需要独立 reference 或检查门

否则优先改现有 Skill 或加子模式。

## 参考资料

- [Anthropic — Equipping agents with Agent Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Anthropic — Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Agent Skills 开放标准](https://agentskills.io/home)
- 方法论锚点：Kent Beck *Tidy First?*（结构 / 行为分离）、Cockburn *Walking Skeleton*、Patton *User Story Mapping*（垂直切片）、MADR ADR（决策驱动 + 多候选对比）
