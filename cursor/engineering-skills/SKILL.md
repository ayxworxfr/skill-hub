---
name: engineering-skills
description: Writes new SKILL.md files, revises existing skills, or audits skills against Anthropic Agent Skills spec and probability-space design patterns. Enforces frontmatter limits (name <=64 chars gerund-form, description <=1024 chars third-person with trigger phrases), SKILL.md body <=500 lines, references one level deep, and the five design patterns (action verbs, check gates, three-layer attention defense, forbidden-output tables, progressive disclosure). Use when the user says "write a skill"/"add a skill"/"新增 skill"/"补一个 SKILL.md"/"refactor this skill"/"改 skill"/"拆 reference"/"audit skill"/"检查 skill 是否合规"/"我这个 skill 触发不准".
---

# Engineering Skills

## Core Principle

写 skill 不是"写一段提示词"，是在概率空间里改地形：用动作动词降低正确路径阻力，用检查门和阻断条件抬高错误路径成本，用三层注意力锚点让关键约束贯穿整个生成过程。

**Anthropic 规范合规** 与 **5 个设计模式落地** 必须同时满足。任一缺失视为不合格，不得声称完成。

## 子模式判定（先做这一步）

| 用户信号 | 子模式 | 加载 reference |
|---|---|---|
| 新增 skill / 写一个 skill / 补 SKILL.md / write a skill | **new** | spec + patterns + skeletons + capabilities |
| 改现有 skill / 拆 reference / 加检查门 / 调 description | **revise** | spec + patterns + capabilities |
| 审计 skill / 检查 skill 是否合规 / audit skill | **audit** | audit-checklist + capabilities |

一个任务可能跨多个子模式（如"新增 skill 并审计"），按顺序套用。

## 适用范围

优先用于：

- 新增 SKILL.md（含 references / assets / scripts）
- 给现有 skill 加缺失 pattern：检查门、Final Gate、禁止输出表、中段自检
- 拆现有 skill 主文件到 references（渐进披露重构）
- 调整 description 让触发更准
- 审计 skill 是否符合 Anthropic spec 和 5 模式

不要用于：

- 写普通业务代码：用 `building`
- 写测试用例：用 `building` 的 test 子模式
- 写 README / 一般文档：直接编辑文件
- 用户问"什么是 skill"/"怎么用 skill"：是问答不是写

## 强制流程（共用骨架）

### 1. 定义 skill 契约

写之前必须答：

- **触发条件**：什么样的用户输入应该激活（中英文短语都列）
- **不触发条件**：哪些相邻意图不该激活（避免抢占其他 skill）
- **子模式**：如有，列出每个子模式的判定信号和加载策略
- **输出骨架**：用户最终看到什么样的回答结构
- **检查门**：什么情况不得声称完成

关键缺口影响判断时先问最少必要问题；不要凭"大概的需求"动手。

### 1.5. 文件预算（结构先行，写任何内容前必做）

AI 最常见的坏习惯是**先把所有内容写进主文件再说"以后拆"**。本步骤强制把拆分判断**前置到下笔前**。

写任何 `## ` 章节正文之前，必须先输出"文件预算表"：

| 文件 | 角色 | 预估行数 | 内容范围（≤3 句） | 留主文件 / 拆 reference 的理由 |
|---|---|---|---|---|
| SKILL.md | 主入口 + 共用骨架 + 路由 | <估> | ... | 必须始终在内存 |
| references/X.md | <子模式 / 长细则> | <估> | ... | 子模式专属 / >100 行细则 / 表 >30 行 |
| ... | | | | |

#### 预算硬约束

- 主 SKILL.md 估算 > 300 行 → 必须再拆，不允许"先写写看"
- 任何子模式专属知识 → 必须独立 reference
- 任何单一主题细则估算 > 100 行 → 必须独立 reference
- 任何表格估算 > 30 行 → 必须独立 reference
- 长示例（完整代码 / 模板）→ 必须独立 reference 或 assets

#### 输出顺序

文件预算表确认后才开始写：

1. 先写所有 references 的骨架（标题 + 章节大纲，可空）
2. 再写主 SKILL.md，正文中显式 `[X.md](references/X.md)` 链接对应 reference
3. 最后回填 references 内容

不允许：

- 主文件先写完一长串再回头拆（注意力已经污染）
- 写到一半才"想起"应该拆（拆完主文件结构混乱）
- 占位 reference（"详见 X 文档"但 X 不存在）

### 2. 加载并核对规范

进入实施前必须读 [anthropic-spec.md](references/anthropic-spec.md)，并对照下列硬性约束：

- `name` ≤ 64 字符，仅小写字母、数字、连字符；用动名词形式（`engineering-skills` 而非 `engineer-skill`）
- `description` ≤ 1024 字符，第三人称，含触发短语，不复述流程
- SKILL.md 正文 ≤ 500 行
- references 一级目录，**不允许** references 内部再嵌套子目录引用
- frontmatter 字段不含 XML 标签、不含 `anthropic` / `claude`

### 3. 加载设计模式（new / revise）

读 [design-patterns.md](references/design-patterns.md)，确保 5 个 pattern 都有具体落点：

| 模式 | 落点位置 | 必备元素 |
|---|---|---|
| 动作化 | 每个步骤 | 动词起手（搜索/列出/检查/统计），无"注意 X" |
| 检查门 | 流程节点 | 规则 + 检测 + 阻断条件三件齐全 |
| 三层防御 | 结构骨架 | Core Principle + 中段自检 + Final Gate |
| 堵死逃逸 | 结尾区域 | 至少一张禁止输出表，列高频借口 |
| 渐进披露 | 全文容量 | >100 行细则进 references，主文件可扫描 |

### 4. 选骨架（new 子模式必做）

读 [skill-skeletons.md](references/skill-skeletons.md)，从四类挑一：

- **工作流型**：步骤有先后依赖（building、debugging、git-safety）
- **检查清单型**：覆盖面优先（reviewing-code、verifying）
- **生成器型**：从输入产出标准化文档（写文档、写 PR）
- **分析决策型**：防止浅层回答（planning、debugging 根因部分）

不知道选哪类时按工作流型走，并显式说明理由。

### 5. 扩展能力判定（关键，别只想着写 markdown）

读 [extension-capabilities.md](references/extension-capabilities.md)，按决策树过一遍：

| 信号 | 用什么能力 |
|---|---|
| 流程含 deterministic 计算/解析/批量操作 | `scripts/` 写脚本，让 AI 调用 |
| 有"必须严格执行不能漏"的硬规则 | `hooks`（PreToolUse / PostToolUse / Stop）硬阻断 |
| 需要外部数据（DB / API / 第三方系统） | 配 MCP server |
| 用户会主动触发固定流程（`/foo`） | 同时做 slash command |
| 团队多人用 / 跨项目分发 | 打包成 plugin + marketplace |
| skill 需要当前 git / 进程状态 | 动态注入 `!`cmd`` |
| 子任务需要独立 context / 不同模型 | 用 subagent |

**核心判定**：能 deterministic 解决的不让 AI 自己算（脚本更稳）；必须严格的不靠 AI 自觉（hook 硬阻断）。

只有上面全部不命中时，才走纯 markdown skill。命中任一都要在输出里说明：用了什么能力 / 为什么不用。

### 6. 中段自检

实施前确认：

- [ ] frontmatter 长度、字符、人称、触发短语已规划合规
- [ ] description 不复述流程，只回答"什么时候用"
- [ ] **文件预算表已写**（Step 1.5），主 SKILL.md 估算 ≤ 300 行
- [ ] 子模式专属知识 / >100 行细则 / >30 行表格 全部已分配到独立 reference
- [ ] references 骨架已先于主文件写出
- [ ] 主文件章节已规划：Core Principle / 适用范围 / 强制流程 / 中段自检 / Final Gate / 禁止输出
- [ ] 5 个设计模式都有具体落点（不是"大概会有"）
- [ ] 已选骨架（new）或已读完原文件（revise）或已加载 audit-checklist（audit）
- [ ] 已对照扩展能力决策树判定：用纯 markdown / scripts / hooks / plugin / MCP / subagent / command 中的哪些组合，每条已有结论

写到一半若主文件实际行数已超 300 → 立即停下，回 Step 1.5 重新分配 references。

任一未通过 → 回 Step 1-5 补，禁止前进。

### 7. 实施（按子模式）

#### 共用规则

- frontmatter 用英文，正文用中文（跟随项目约定）
- 所有规则动作化：用"搜索/列出/检查/统计/对照"代替"注意/关注/留意"
- 量化能量化的：行数、阈值、次数、错误等级、字符上限
- 不写占位、TODO、"以后补"，全部落到具体可执行
- references 一级目录，不嵌套
- 现有项目格式风格（表头、序号、icon）跟随其他 skill，不引入新风格
- 删除作废旧逻辑，不注释保留

#### new 子模式

- 主文件写完立即写所有引用的 references（不允许"先占位以后补"）
- 按所选骨架填充对应章节
- 至少一张禁止输出表，列 5 条以上高频借口
- 在 README.md 路由表登记新 skill
- 决策树命中的扩展能力同步落地：`scripts/<name>.py`、配套 hook 配置示例、`.mcp.json` 片段、plugin 打包说明等

#### revise 子模式

- 先读现有 SKILL.md 全文 + 所有 references，列出当前缺什么 / 多什么
- 拆分时保留原内容，不删减；只迁移位置
- 拆完后主文件必须仍然自洽：用户只读主文件能跑完主流程
- references 通过明确链接进入，不允许"详见某文档"模糊引用

#### audit 子模式

- 按 [audit-checklist.md](references/audit-checklist.md) 逐项核对
- 输出三档结果：Pass / Warn / Block
- 每个 Block 项必须给具体修复建议（改哪一行、改成什么）
- 不允许"整体看起来不错"

### 8. 验证

完成后必须做下列至少 3 项：

- **触发模拟**：构造 2-3 句用户可能输入，对照 description 判断是否触发，未触发的说明原因
- **行数核对**：`wc -l SKILL.md`，确认 ≤ 500
- **字符核对**：数 description 字符数，确认 ≤ 1024
- **链接核对**：所有 references 链接路径真实存在
- **冲突核对**：触发短语是否会抢占其他 skill；如抢占则补"不触发"条款
- **README 核对**：new 子模式必须更新 README
- **脚本/hook/plugin 核对**：含 scripts 时确认依赖声明 + 输入输出契约；含 hook 配置时确认 matcher 与 exit code 协议；含 plugin 时确认 `plugin.json` 字段齐

无法做某项验证时显式写"未做 X，原因：..."，不省略。

## Final Gate

输出前逐项确认：

- [ ] frontmatter 合规：name 形式、description 长度、人称、触发短语齐全
- [ ] description 没复述流程
- [ ] 5 个设计模式都有具体落点（能引用到具体行）
- [ ] 中段自检和 Final Gate 都存在
- [ ] 至少一张禁止输出表，≥5 条
- [ ] **`wc -l SKILL.md` 实测 ≤ 300 行**（硬上限 500，目标 300）
- [ ] **任何 reference > 300 行 → 再拆**
- [ ] 子模式专属知识 / >100 行细则 / >30 行表格 全部在 references
- [ ] 主文件无"详见 X"模糊引用，全部用具体 markdown 链接
- [ ] new：已选骨架，已加 README，所有 references 已写完
- [ ] revise：主文件拆分后仍可独立运行
- [ ] audit：每个 Block 项有修复建议
- [ ] 已对扩展能力决策树过一遍：deterministic 步骤是否用 scripts、硬规则是否用 hook、外部数据是否用 MCP、是否需要 plugin 打包；不用每条的理由已显式写出
- [ ] 没有触发"禁止输出模式"任一行

任一未通过不得声称完成。

## 共用检查门

以下情况不得声称完成：

- description 超过 1024 字符或不是第三人称
- description 用流程总结代替触发条件（"按 5 步审查代码"）
- 主文件超过 500 行未下沉
- references 内部再引用更深层文件
- 5 模式中任一无落点
- 触发短语会大量抢占现有 skill 但未列"不触发"条款
- new 子模式漏更新 README
- 流程明显含 deterministic 计算却让 AI 自己算，未用 scripts
- 含"必须严格执行"硬规则却只写 markdown，未配 hook
- 需要外部数据但 skill 里硬编码 API 调用，未走 MCP

## 共用禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "这个 skill 比较简单不需要检查门" | 写出至少 3 条阻断条件 |
| "可以根据需要扩展" | 列出当前要做的全部章节，不留占位 |
| "description 大概意思就行" | 数到字符数 ≤1024，第三人称，含触发短语 |
| "其他规则可以参考别的 skill" | 把所需规则写进当前 skill 或显式 references 链接 |
| "正文太长以后再拆" | 当前就拆到 references，不留延期 |
| "先把内容写完整再考虑拆分" | Step 1.5 文件预算先行；写之前就分配好 references |
| "这个章节先放主文件" | 子模式专属 / >100 行细则 / >30 行表格 必须独立 reference |
| "详见某文档" | 用具体 `[X.md](references/X.md)` 链接 |
| "主文件 400 行还能接受" | 目标 300，硬上限 500；>300 立即拆 |
| "动名词大概意思就行" | 用 `processing-X`/`writing-Y` 形式，不用 `process-X` |
| "注意要 X" | 改成"搜索 X / 列出 X / 检查 X 是否符合 Y" |
| "整体合规" | 列出每条 spec 项的核对结果 |
| "让 AI 自己算/自己解析就行" | deterministic 步骤改写脚本调用 |
| "靠 AI 自觉不会漏" | 关键约束加 PreToolUse / Stop hook 硬阻断 |
| "skill 里直接调外部 API 就行" | 走 MCP server，skill 只编排 |

## 输出骨架

```markdown
## 子模式

- <new / revise / audit，多选时按出现顺序>

## skill 契约

- 触发条件：
- 不触发条件：
- 子模式（如有）：
- 输出结构：
- 检查门要点：

## 规范核对

- name（字符数 / 动名词）：
- description（字符数 / 人称 / 触发短语数量）：
- 主文件行数：
- references 列表：

## 5 模式落点

- 动作化：
- 检查门：
- 三层防御：
- 堵死逃逸：
- 渐进披露：

## 扩展能力决策

- scripts：<是/否，理由>
- hooks：<是/否，理由>
- MCP：<是/否，理由>
- subagent：<是/否，理由>
- slash command：<是/否，理由>
- plugin 打包：<是/否，理由>
- 动态注入：<是/否，理由>

## 实施

- 新增/修改文件：
- 拆分到 references：
- 新增 scripts / hooks / MCP / plugin 配置：
- README 更新：

## 验证

- 触发模拟：<至少 2 句输入 + 是否触发判断>
- 行数核对：
- 字符核对：
- 链接核对：
- 未验证：

## 残留

- <未验证项或风险；没有写"无">
```

子模式额外输出：audit 子模式追加按 [audit-checklist.md](references/audit-checklist.md) 的 Pass/Warn/Block 列表。
