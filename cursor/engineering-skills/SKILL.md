---
name: engineering-skills
description: Writes new SKILL.md files, revises existing skills, or audits skills against Anthropic Agent Skills spec and probability-space design patterns. Enforces frontmatter limits (name <=64 chars gerund-form, description <=1024 chars third-person with trigger phrases), SKILL.md body <=500 lines, references one level deep, and the five design patterns (action verbs, check gates, three-layer attention defense, forbidden-output tables, progressive disclosure). Use when the user says "write a skill"/"add a skill"/"新增 skill"/"补一个 SKILL.md"/"refactor this skill"/"改 skill"/"拆 reference"/"audit skill"/"检查 skill 是否合规"/"我这个 skill 触发不准".
---

# Engineering Skills

## Core Principle

写 skill 不是写一段提示词，是在概率空间里改地形：动作动词降低正确路径阻力，检查门和阻断条件抬高错误路径成本，progressive disclosure 让主文件保持可扫描。

**Anthropic 规范合规** 与 **5 个设计模式落地** 必须同时满足。任一缺失视为不合格。

**结构先于内容**：写任何章节正文之前，先输出文件预算表。没出预算表禁止动笔。

## 子模式判定

| 用户信号 | 子模式 |
|---|---|
| 新增 skill / 写一个 skill / 补 SKILL.md / write a skill | **new** |
| 改现有 skill / 拆 reference / 加检查门 / 调 description | **revise** |
| 审计 skill / 检查 skill 是否合规 / audit skill | **audit** |

跨多个子模式时按顺序套用。

## 适用范围

- 新增 SKILL.md（含 references / scripts / assets）
- 给现有 skill 加缺失 pattern：检查门、Final Gate、禁止输出表
- 拆主文件到 references（progressive disclosure 重构）
- 调整 description 让触发更准
- 审计 skill 是否合规

不要用于：写普通业务代码（用 building）、写测试用例（building/test 子模式）、写一般文档（直接编辑）、回答"什么是 skill"（是问答不是写）。

## 强制流程

### 1. 设计 skill 结构（动笔前必做）

下笔写正文之前，先做完三件事：

1. **回答 skill 契约**：触发条件 / 不触发条件 / 子模式 / 输出结构 / 检查门要点
2. **输出文件预算表**：列出预期文件清单 + 各自行数估算 + 内容范围 + 留主/拆出的理由
3. **建空骨架**：所有 references 文件先建好（标题 + 章节大纲，正文可空）

详见 [structure-planning.md](references/structure-planning.md)，包含目录形态、决策表、命名规则、写入顺序、反模式。

预算硬约束：

- 主 SKILL.md 估算 > 300 行 → 必须再拆，不允许"先写写看"
- 子模式专属知识 → 独立 reference
- 单一主题细则 > 100 行 → 独立 reference + 文首 TOC
- 表格 > 30 行 → 独立 reference
- 长示例 / 完整模板 → reference 或 assets
- 确定性计算 → scripts，不让 AI 自己算
- 必须严格执行的硬规则 → hooks，不靠 AI 自觉

不允许：主文件先写一长串再回头拆 / 写到一半才"想起"应该拆 / 占位 reference / 模糊指向（"详见某段"）。

### 2. 核对 Anthropic 规范

加载 [anthropic-spec.md](references/anthropic-spec.md)，逐项核对：

- `name` ≤ 64 字符，`a-z0-9-`，**动名词**形式，与目录名一致，不含 `anthropic`/`claude`
- `description` ≤ 1024 字符，第三人称，含触发短语（USE WHEN 模式或具体短语列举），不复述流程
- SKILL.md 正文 ≤ 500 行（目标 ≤ 300）
- references 一级目录，不嵌套引用第二跳
- frontmatter 不含 XML 标签

### 3. 选骨架（new 子模式必做）

加载 [skill-skeletons.md](references/skill-skeletons.md)，从四类挑一：

| 骨架 | 适用 |
|---|---|
| **工作流型** | 步骤有先后依赖（building、debugging、git-safety） |
| **检查清单型** | 覆盖面优先（reviewing-code、verifying） |
| **生成器型** | 从输入产出标准化文档（写文档、写 PR） |
| **分析决策型** | 防止浅层回答（planning、debugging 根因部分） |

不知道选哪类时按工作流型走，并显式说明理由。

### 4. 落地 5 个设计模式

加载 [design-patterns.md](references/design-patterns.md)，确保 5 个 pattern 都有具体落点（能引用到主文件 / reference 的具体行）：

| 模式 | 落点位置 | 必备元素 |
|---|---|---|
| 动作化 | 每个步骤 | 动词起手（搜索 / 列出 / 检查 / 统计），无"注意 X" |
| 检查门 | 流程节点 | 规则 + 检测 + 阻断条件三件齐全 |
| 三层防御 | 结构骨架 | Core Principle（开头）+ 步骤内自检（中段）+ Final Gate（结尾） |
| 堵死逃逸 | 结尾区域 | 至少一张禁止输出表，列高频借口 ≥5 条 |
| 渐进披露 | 全文容量 | >100 行细则进 references，主文件保持可扫描 |

### 5. 扩展能力判定

加载 [extension-capabilities.md](references/extension-capabilities.md)，按下表过一遍。命中任一都要在输出里说明：用了什么能力 / 为什么不用。

| 信号 | 用什么能力 |
|---|---|
| 流程含 deterministic 计算 / 解析 / 批量操作 | `scripts/` |
| "必须严格执行不能漏"的硬规则 | `hooks`（PreToolUse / PostToolUse / Stop） |
| 需要外部数据（DB / API / 第三方系统） | MCP server |
| 用户会主动触发固定流程（`/foo`） | slash command |
| 团队多人用 / 跨项目分发 | plugin + marketplace |
| 需要当前 git / 进程状态 | 动态注入 `!`cmd`` |
| 子任务需要独立 context / 不同模型 | subagent |

只有上面全部不命中时才走纯 markdown skill。

### 6. 实施

#### 共用规则

- frontmatter 用英文，正文用中文（项目约定）
- 所有规则动作化：用"搜索 / 列出 / 检查 / 统计 / 对照"代替"注意 / 关注 / 留意"
- 量化能量化的：行数、阈值、次数、错误等级、字符上限
- references 一级目录，不嵌套
- 删除作废旧逻辑，不注释保留
- 跟随项目现有 skill 的格式风格（表头、序号、icon），不引入新风格

#### new 子模式

- 按 Step 1 文件预算表的顺序：先建所有 references 骨架，再写主文件，最后回填 references
- 主文件用 `[X.md](references/X.md)` 链接 references，不允许"详见某文档"模糊引用
- 至少一张禁止输出表，≥5 条高频借口
- 决策树命中的扩展能力同步落地：`scripts/<name>.py` / hook 配置 / `.mcp.json` 片段 / plugin 说明
- 如外层维护了 skill 集合的索引/路由文档（如 `README.md`），同步登记；不存在则跳过

#### revise 子模式

- 先读现有 SKILL.md 全文 + 所有 references，列出当前缺什么 / 多什么
- 再做文件预算表，标注新增 / 修改 / 删除哪些文件
- 拆分时保留原内容，只迁移位置；不删减用户改动
- 拆完后主文件必须仍然自洽：用户只读主文件能跑完主流程

#### audit 子模式

- 加载 [audit-checklist.md](references/audit-checklist.md)，逐项核对
- 输出三档：Pass / Warn / Block
- 每个 Block 给具体修复建议（改哪一行、改成什么），不允许"整体看起来不错"

### 7. 验证

完成后必须做下列至少 3 项：

- **触发模拟**：构造 2-3 句用户可能输入，对照 description 判断是否触发；未触发的说明原因
- **行数核对**：`wc -l SKILL.md`，确认 ≤ 500（目标 ≤ 300）
- **字符核对**：数 description 字符数，确认 ≤ 1024
- **链接核对**：所有 references 链接路径真实存在
- **冲突核对**：触发短语是否会抢占其他 skill；如抢占则补"不触发"条款
- **外层索引核对**：如外层维护 skill 路由文档（如 `README.md`），new 子模式同步登记；无则跳过
- **scripts/hook/plugin 核对**：含 scripts 时确认依赖声明 + 输入输出契约；含 hook 时确认 matcher + exit code 协议；含 plugin 时确认 `plugin.json` 字段齐

无法做某项验证时显式写"未做 X，原因：..."，不省略。

## Final Gate

输出前按顺序扫一遍。任一未通过 → 回对应步骤改写，**禁止声称完成**。

1. **扫 frontmatter**：name 动名词形式 / description 字符数 ≤1024 + 第三人称 + 含触发短语 / 不复述流程
2. **扫主文件行数**：`wc -l` 实测 ≤ 500，目标 ≤ 300
3. **扫文件预算落地**：每个 reference 都被主文件 `[X.md](references/X.md)` 链接到；不存在"详见某段"模糊引用；不存在 reference 内部跳到第二跳
4. **扫 5 模式落点**：动作化（动词起手）/ 检查门（规则+检测+阻断）/ 三层防御（Core Principle + 中段 + Final Gate）/ 堵死逃逸（≥5 条禁止输出表）/ 渐进披露（>100 行细则在 references）
5. **扫禁止输出表第 1 列字面量**：每条字面量都不应出现在自己的输出中
6. **扫子模式专属交付**：new → 所有 references 已写满 + 外层索引（如有）已登记；revise → 主文件拆后仍自洽；audit → 每个 Block 有具体修复建议
7. **扫扩展能力**：决策树每条都有结论（用 / 不用 + 理由）；命中 scripts/hooks/MCP/plugin 时配套文件已落地

## 共用禁止输出

| 禁止输出 | 替代动作 |
|---|---|
| "这个 skill 简单不需要检查门" | 写出至少 3 条阻断条件 |
| "可以根据需要扩展" | 列出当前要做的全部章节，不留占位 |
| "description 大概意思就行" | 数到字符数 ≤1024，第三人称，含触发短语 |
| "其他规则参考别的 skill" | 把所需规则写进当前 skill 或 `[X.md](path)` 链接 |
| "正文太长以后再拆" | Step 1 文件预算先行，当前就拆到 references |
| "先把内容写完整再考虑拆分" | 写主文件之前先建 references 骨架 |
| "详见某文档" | 用具体 `[X.md](references/X.md)` 链接 |
| "动名词大概意思就行" | `processing-X` / `writing-Y`，不用 `process-X` |
| "注意要 X" | 改成"搜索 X / 列出 X / 检查 X 是否符合 Y" |
| "整体合规" | 列出每条 spec 项的核对结果 |
| "让 AI 自己算就行" | 确定性步骤改写脚本调用 |
| "靠 AI 自觉不会漏" | 关键约束加 PreToolUse / Stop hook 硬阻断 |
| "skill 直接调外部 API 就行" | 走 MCP server，skill 只编排 |

## 输出骨架

完整模板见 [output-skeleton.md](references/output-skeleton.md)。核心段：子模式 / skill 契约 / 文件预算 / 规范核对 / 5 模式落点 / 扩展能力决策 / 实施 / 验证 / 残留。

audit 子模式追加 Pass/Warn/Block 表 + 修复建议。
