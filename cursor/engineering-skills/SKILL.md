---
name: engineering-skills
description: Writes, revises, or audits SKILL.md files including frontmatter, references, and design patterns. Use when the user says "write a skill"/"add a skill"/"新增 skill"/"补一个 SKILL.md"/"refactor this skill"/"改 skill"/"拆 reference"/"audit skill"/"检查 skill 是否合规"/"我这个 skill 触发不准". Skip for:regular code, business documentation, or general README writing.
---

# Engineering Skills

## Core Principle

写 skill 不是写一段提示词，是在概率空间里改地形：动作动词降低正确路径阻力，检查门和阻断条件抬高错误路径成本，progressive disclosure 让主文件保持可扫描。

锚定原则（**唯一完整声明**，下文按编号引用，不复述）：

- **P1 结构先于内容**：动笔前先做文件预算 + 建空骨架（详 §2.1）
- **P2 单一来源（DRY）**：同一规则只完整声明一次，其他位置引用编号
- **P3 三层防御上限**：Core 声明 + 中段自检引用 + Final Gate 引用——第 4 处即噪音
- **P4 整数编号 + 章节正交**：步骤 X.Y 整数（禁 X.5 / X.0 / Xa）；维度互斥不交叉
- **P5 术语统一**：外来术语在小词典定义，避免跨 skill 漂移
- **P6 动作化**：每个步骤动词起手（搜索 / 列出 / 检查 / 统计 / 对照），禁"注意 X"
- **P7 渐进披露**：>100 行细则进 references；主文件 ≤ 500（目标 ≤ 300）
- **P8 spec 合规**：name 动名词 + description ≤1024 + 第三人称 + 含触发短语 + 不复述流程

## 1. 决策框架

### 1.1 是否走 engineering-skills

| 任务类型 | 走哪 |
|---|---|
| 新增 SKILL.md（含 references / scripts / assets） | engineering-skills |
| 给现有 skill 加缺失 pattern（检查门 / Final Gate / 禁止输出表） | engineering-skills |
| 拆主文件到 references（progressive disclosure 重构） | engineering-skills |
| 调整 description 让触发更准 | engineering-skills |
| 审计 skill 是否合规 | engineering-skills |
| 写普通业务代码 | [building](../building/SKILL.md) |
| 写测试用例 | [building](../building/SKILL.md) test 子模式 |
| 写一般文档 | 直接编辑 |
| 回答"什么是 skill" | 是问答不是写，直接答 |

### 1.2 子模式判定

| 用户信号 | 子模式 |
|---|---|
| 新增 skill / 写一个 skill / 补 SKILL.md / write a skill | **new** |
| 改现有 skill / 拆 reference / 加检查门 / 调 description | **revise** |
| 审计 skill / 检查 skill 是否合规 / audit skill | **audit** |

跨多个子模式时按顺序套用。

## 2. 执行流程

### 2.1 设计文件预算（动笔前必做）

按 P1，下笔写正文前完成三件事：

1. **回答 skill 契约**：触发条件 / 不触发条件 / 子模式 / 输出结构 / 检查门要点
2. **输出文件预算表**：列预期文件清单 + 各自行数估算 + 内容范围 + 留主 / 拆出的理由
3. **建空骨架**：所有 references 文件先建好（标题 + 章节大纲，正文可空）

详见 [structure-planning.md](references/structure-planning.md)，包含目录形态、决策表、命名规则、写入顺序、反模式。

预算硬约束（按 P7）：

- 主 SKILL.md 估算 > 300 行 → 必须再拆
- 子模式专属知识 → 独立 reference
- 单一主题细则 > 100 行 → 独立 reference + 文首 TOC
- 表格 > 30 行 → 独立 reference
- 长示例 / 完整模板 → reference 或 assets
- 确定性计算 → scripts，不让 AI 自己算
- 必须严格执行的硬规则 → hooks，不靠 AI 自觉

### 2.2 核对 Anthropic 规范

加载 [anthropic-spec.md](references/anthropic-spec.md)，按 P8 逐项核对：

- `name` ≤ 64 字符，`a-z0-9-`，**动名词**形式，与目录名一致，不含 `anthropic` / `claude`
- `description` ≤ 1024 字符，第三人称，含触发短语（USE WHEN 模式或具体短语列举），不复述流程
- SKILL.md 正文 ≤ 500 行（目标 ≤ 300）
- references 一级目录，不嵌套引用第二跳
- frontmatter 不含 XML 标签

### 2.3 选骨架（仅 new 子模式）

加载 [skill-skeletons.md](references/skill-skeletons.md)，从四类挑一：

| 骨架 | 适用 |
|---|---|
| **工作流型** | 步骤有先后依赖（building / debugging / git-safety） |
| **检查清单型** | 覆盖面优先（reviewing-code / verifying） |
| **生成器型** | 从输入产出标准化文档（写文档 / 写 PR） |
| **分析决策型** | 防止浅层回答（planning / debugging 根因部分） |

不知道选哪类时按工作流型走，并显式说明理由。

### 2.4 落地 5 个设计模式

加载 [design-patterns.md](references/design-patterns.md)。5 个 pattern 都要有具体落点（能引用到主文件 / reference 的具体行）：

| # | 模式 | 落点位置 | 必备元素 |
|---|---|---|---|
| **D1** | 动作化 | 每个步骤 | 动词起手（P6） |
| **D2** | 检查门 | 流程节点 | 规则 + 检测 + 阻断条件 三件齐全 |
| **D3** | 三层防御 | 结构骨架 | Core Principle 完整声明 + 步骤内自检引用编号 + Final Gate 扫描引用（P3） |
| **D4** | 堵死逃逸 | 结尾区域 | 一张禁止输出表，列高频诱导短语 ≤6 条（不抄 H 项的活，能映射到 H 即删） |
| **D5** | 渐进披露 | 全文容量 | >100 行细则进 references；主文件可扫描（P7） |

### 2.5 扩展能力判定

加载 [extension-capabilities.md](references/extension-capabilities.md)，按下表过一遍。命中任一都要在输出里说明：用了什么能力 / 为什么不用。

| 信号 | 用什么能力 |
|---|---|
| 流程含 deterministic 计算 / 解析 / 批量操作 | `scripts/` |
| "必须严格执行不能漏"的硬规则 | `hooks`（PreToolUse / PostToolUse / Stop） |
| 需要外部数据（DB / API / 第三方系统） | MCP server |
| 用户主动触发固定流程（`/foo`） | slash command |
| 团队多人用 / 跨项目分发 | plugin + marketplace |
| 需要当前 git / 进程状态 | 动态注入 `!`cmd`` |
| 子任务需要独立 context / 不同模型 | subagent |

只有上面全部不命中时才走纯 markdown skill。

### 2.6 实施（按子模式）

#### 共用规则

- frontmatter 用英文，正文用中文（项目约定）
- 量化能量化的：行数、阈值、次数、错误等级、字符上限
- references 一级目录，不嵌套
- 删除作废旧逻辑，不注释保留
- 跟随项目现有 skill 的格式风格（表头、序号、icon），不引入新风格

#### new 子模式

- 按 §2.1 文件预算表的顺序：先建所有 references 骨架，再写主文件，最后回填 references
- 主文件用 `[X.md](references/X.md)` 链接 references（H3）
- 一张禁止输出表，列 ≤6 条高频诱导短语（D4）
- 决策树命中的扩展能力同步落地：`scripts/<name>.py` / hook 配置 / `.mcp.json` 片段 / plugin 说明（H6）
- 如外层维护 skill 集合的索引 / 路由文档（如 `README.md`），同步登记；不存在则跳过

#### revise 子模式

- 先读现有 SKILL.md 全文 + 所有 references，列出当前缺什么 / 多什么
- 按 [anti-fragmentation.md](references/anti-fragmentation.md) §2 扫 4 类化石（信号 A/B/C/D），逐条给具体修复指令
- 再做文件预算表，标注新增 / 修改 / 删除哪些文件
- 拆分时保留原内容，只迁移位置；不删减用户改动
- 拆完后主文件必须仍然自洽：用户只读主文件能跑完主流程

#### audit 子模式

- 加载 [audit-checklist.md](references/audit-checklist.md)，逐项核对
- 加载 [anti-fragmentation.md](references/anti-fragmentation.md) §3，把 4 类化石追加为 Block 项
- 输出三档：Pass / Warn / Block
- 每个 Block 给具体修复建议（改哪一行、改成什么），不允许"整体看起来不错"

### 2.7 验证

完成后必须做下列至少 3 项：

- **触发模拟**：构造 2-3 句用户可能输入，对照 description 判断是否触发；未触发的说明原因
- **行数核对**：`wc -l SKILL.md`，按 P7
- **字符核对**：数 description 字符数，按 P8
- **链接核对**：所有 references 链接路径真实存在
- **冲突核对**：触发短语是否会抢占其他 skill；如抢占则补"不触发"条款
- **外层索引核对**：如外层维护 skill 路由文档（如 `README.md`），new 子模式同步登记；无则跳过
- **scripts / hook / plugin 核对**：含 scripts 时确认依赖声明 + 输入输出契约；含 hook 时确认 matcher + exit code 协议；含 plugin 时确认 `plugin.json` 字段齐

无法做某项验证时显式写"未做 X，原因：..."，不省略。

## 3. 质量门

### 3.1 输出前硬阻断表（唯一完整声明）

输出 skill 前任意一项命中 → 停下回对应步骤。下文 Final Gate 按编号引用，不复述：

| # | 硬阻断 | 触发信号 | 替代动作 |
|---|---|---|---|
| **H1** | 缺文件预算就动笔 | 主文件已开始写但 §2.1 三件事未做 / "详见某段"模糊引用 | 出预算表 + 建空骨架 + 具体链接（P1 + 用 `[X.md](references/X.md)`） |
| **H2** | 主文件超容量不拆 | `wc -l` > 500 或 > 300 软目标无理由 | 拆 reference（P7） |
| **H3** | 同规则 ≥3 处完整声明 | 主文件多处复述同一规则正文 | 选一处完整声明，其他位置引用 P / H / § 编号（P2 + P3） |
| **H4** | 外来术语断层 | 主文件出现别的 skill 字面量但本文件无解释 | 加术语小词典或换本 skill 自有术语（P5） |
| **H5** | frontmatter 不合规 | name 非动名词 / description > 1024 / 复述流程 | 按 P8 改 |
| **H6** | 扩展能力命中未落地 | §2.5 决策树命中但配套文件缺失 | 落 `scripts/` / hook 配置 / `.mcp.json` / plugin |

步骤编号含小数 / 章节维度交叉 / 禁止输出表过载等结构性化石，见 [anti-fragmentation.md](references/anti-fragmentation.md) 信号 A / C / E，revise / audit 子模式必扫。

### 3.2 Final Gate

输出前扫流程层级三件事（不重扫 H 表 / 禁止输出表，那是 §3.1 / §4 各自的事）。任一违规不得声称完成：

1. **扫 5 模式落点**（§2.4 D1-D5）：每个 pattern 能引用到主文件 / reference 的具体行
2. **扫子模式专属交付**：new → references 写满 + 外层索引登记；revise → 拆后主文件自洽 + 化石诊断已给修复指令（含 anti-fragmentation 信号 A-E）；audit → 每个 Block 有具体修复建议
3. **扫验证段**（§2.7）：≥3 项实做，未做项写明原因

## 4. 共用禁止输出

高频诱导短语 ≤6 条（H 项已覆盖的不重复列；frontmatter / 术语 / 维度交叉 / 编号小数等结构性诱因见 §3.1 + anti-fragmentation 速查）：

| 禁止输出 | 替代动作 |
|---|---|
| "这个 skill 简单不需要检查门" | 写 ≥3 条阻断条件（D2） |
| "可以根据需要扩展" / "正文太长以后再拆" | §2.1 文件预算先行（H1） |
| "其他规则参考别的 skill" / "详见某文档" | 用具体 `[X.md](path)` 链接（H1） |
| "注意要 X" | 改成"搜索 X / 列出 X / 检查 X 是否符合 Y"（P6） |
| "让 AI 自己算就行" / "靠 AI 自觉不会漏" | §2.5 决策树命中即配套落地（H6） |
| "再加一层防御就稳了" / "Final Gate 多扫一遍 H 更稳" | 三层防御已是上限（P3）；H 表是单一来源（H3） |

## 5. 输出骨架

完整模板见 [output-skeleton.md](references/output-skeleton.md)。核心段：子模式 / skill 契约 / 文件预算 / 规范核对 / 5 模式落点 / 扩展能力决策 / 实施 / 验证 / 残留。

audit 子模式追加 Pass / Warn / Block 表 + 修复建议。
