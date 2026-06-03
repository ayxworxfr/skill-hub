# Audit Checklist

audit 子模式专用。逐项核对，输出 Pass / Warn / Block。**Block 项必须给具体修复建议**（改哪一行、改成什么），不允许"整体不错"。

## 一、Anthropic 规范合规（硬性）

### A1. frontmatter

- [ ] `name` ≤ 64 字符
- [ ] `name` 全小写、数字、连字符
- [ ] `name` 是动名词形式（`writing-X` / `processing-X`）
- [ ] `name` 与目录名一致
- [ ] `name` 不含 `anthropic` / `claude`
- [ ] `description` 存在且非空
- [ ] `description` ≤ 1024 字符（**数字符**）
- [ ] `description` 第三人称
- [ ] `description` 含触发短语（USE WHEN 模式或具体语句列举）
- [ ] `description` 不复述流程步骤
- [ ] frontmatter 不含 XML 标签

任一不通过 → **Block**

### A2. 文件大小

- [ ] SKILL.md 正文 ≤ 500 行（`wc -l`）
- [ ] references 一级目录，无嵌套二级引用
- [ ] 单个 reference ≤ 300 行（>300 考虑再拆）

主文件超 500 行 → **Block**；reference 超 300 行 → **Warn**

### A3. 结构

- [ ] 含 `Core Principle` 章节
- [ ] 含强制流程或检查清单
- [ ] 含 `Final Gate` 或等价的结尾拦截
- [ ] 含至少一张禁止输出表
- [ ] 输出格式有具体骨架（不是"按需输出"）

任一缺失 → **Block**

## 二、5 设计模式覆盖

### B1. 动作化

- [ ] 每条规则起手是动词
- [ ] 没有"注意 X / 关注 Y / 留意 Z"裸声明
- [ ] 量词具体（行数、阈值、次数），无"一些 / 大概 / 适当"

裸名词式规则 ≥ 3 处 → **Block**；偶发 → **Warn**

### B2. 检查门

- [ ] 至少 3 个检查门
- [ ] 每个检查门含规则 + 检测 + 阻断三要素
- [ ] 阻断条件具体（"不得继续"/"回 Step N 重做"）

少于 3 个 → **Warn**；任一无阻断条件 → **Block**

### B3. 三层注意力锚点

- [ ] Core Principle 声明核心约束
- [ ] 流程中段有自检（"中段自检"或等价节点）
- [ ] Final Gate 在结尾拦截
- [ ] 三处都指向同一组核心约束（不是各说各的）

中段自检缺失 → **Block**

### B4. 堵死逃逸

- [ ] 至少一张禁止输出表
- [ ] 禁止条目 ≥ 5 条
- [ ] 每条有"替代动作"列

少于 5 条 → **Warn**；无替代动作 → **Block**

### B5. 渐进披露（最常被忽略的模式，重点查）

- [ ] 主文件 ≤ 300 行（目标）
- [ ] 主文件 ≤ 500 行（硬上限）
- [ ] 单个 reference ≤ 300 行
- [ ] 主文件无 > 100 行的单一主题细则
- [ ] 子模式专属知识下沉到 references（每个子模式一个独立 reference）
- [ ] 长表格（> 30 行）下沉到 references
- [ ] 长示例（完整代码 / 模板）下沉到 references 或 assets
- [ ] references 通过显式 markdown 链接进入，不"详见某文档"
- [ ] 所有 references 都被主文件链接到（无孤儿文件）

主文件 300-500 行 → **Warn**（建议拆）；主文件 > 500 行 → **Block**；
reference > 300 行 → **Warn**；
单一主题 > 100 行未拆 → **Warn**；
子模式专属知识堆主文件 → **Block**；
"详见某文档"模糊引用 → **Block**

## 三、扩展能力使用

详细决策见 [extension-capabilities.md](extension-capabilities.md)。审计时检查：

### C1. Scripts

- [ ] 流程含 deterministic 计算 / 解析 / 批量操作时，是否用 `scripts/`
- [ ] 脚本统一放在 `scripts/` 一级子目录，没散在 skill 根目录
- [ ] 含 scripts 时，SKILL.md 显式标出调用路径
- [ ] SKILL.md 没有复读 >3 行的脚本执行逻辑
- [ ] 脚本文件名跟随宿主语言惯例（Python → snake_case，Shell / Node → kebab-case）
- [ ] 列出依赖包（pip / npm 等）
- [ ] 给出输入/输出契约

deterministic 任务全靠 AI 自算 → **Block**；脚本散主目录 / SKILL.md 复读脚本内容 → **Block**；Python 脚本用 kebab-case → **Warn**（违反 PEP 8 且不可 import）；含 script 但未列依赖 → **Warn**

### C2. Hooks

- [ ] 含"必须严格执行"硬规则时，是否配 PreToolUse / Stop hook
- [ ] hook 配置示例 matcher 与 exit code 协议正确
- [ ] hook command 字段不内联 >3 行 Python / shell（多行逻辑必须抽到 `scripts/`）
- [ ] hook 引用脚本时给出可替换的路径占位符（如 `<skills-dir>/...`）
- [ ] hook 不嵌入 200 行业务逻辑（保持薄）

硬规则只写 markdown 没有 hook → **Warn**（如果是 plugin 场景则 **Block**）；hook command 内联多行执行逻辑 → **Block**

### C3. MCP

- [ ] 需要外部数据时是否走 MCP，而非在 skill 里硬编码 API
- [ ] MCP 工具引用名清晰

skill 里硬调外部 API → **Block**

### C4. Plugin 打包

- [ ] 含 hooks + skills + MCP 组合时是否打包成 plugin
- [ ] 团队多人共用时是否 plugin + marketplace
- [ ] `plugin.json` 字段（name/version/description）齐

跨多个组件却散在 settings.json + skill 目录 → **Warn**

### C5. Subagent / Command / 动态注入

- [ ] 用户主动触发的固定流程是否同时做 slash command
- [ ] 需要并行 / 隔离 context / 不同模型时是否用 subagent
- [ ] 需要当前 git/进程状态是否用 `!`cmd`` 动态注入

## 四、触发与边界

- [ ] description 触发短语覆盖中英文（项目用中文时）
- [ ] 列出"不触发"条款（避免抢占）
- [ ] 与现有 skill 无大量重叠（grep 关键触发词）
- [ ] 子模式判定（如有）信号清晰、不重叠

触发词与其他 skill 大量重叠且无"不触发"条款 → **Block**

## 五、与项目现有约定一致

- [ ] frontmatter 语言（项目用英文）
- [ ] 正文语言（项目用中文）
- [ ] 表格 / 序号 / icon 风格与其他 skill 一致
- [ ] 输出骨架格式与其他 skill 一致
- [ ] 在 README 路由表登记

风格不一致 → **Warn**；漏登 README → **Block**

## 六、可执行性

- [ ] 验证步骤含具体命令（不是"跑一下测试"）
- [ ] 验证步骤可复制粘贴
- [ ] 引用的 references 路径真实存在
- [ ] 引用的其他 skill 名字正确

引用不存在的文件 → **Block**

## 输出格式

```markdown
# Audit: <skill 名>

## 概览
- Pass: N
- Warn: N
- Block: N

## Block 项（必须修）

### 1. <项目编号 + 检查项>
- 现状：<具体引用某行>
- 修复：<改成什么>

### 2. ...

## Warn 项（建议修）

### 1. <项目编号 + 检查项>
- 现状：
- 建议：

## Pass 项

- 列出已通过的关键项（不必全列，列代表性的）

## 结论

- 是否可发布：<是/否>
- 必须修的项数：
- 建议修的项数：
```

## audit 禁止输出

| 禁止输出 | 替代动作 |
|---|---|
| "整体看起来不错" | 列每条核对结果 |
| "小问题不影响使用" | 标记 Warn 并给修复建议 |
| "建议优化一下" | 写出具体改哪一行、改成什么 |
| "符合规范" | 引用具体 spec 项 + 数值（字符数 / 行数） |
| "5 个模式都有" | 引用具体行号或章节标题 |

## 常见缺陷模式（命中即 Block）

- description 用 `I help / You should` → 改第三人称
- description 复述步骤"按 N 步审查 X" → 改为"用于 X 任务时使用"
- 主文件没有"中段自检" → 加一节
- 检查门只有规则没有阻断 → 加"不得继续"
- 禁止输出表 < 5 条或没有替代动作 → 补
- 子模式知识全堆主文件 → 拆 references
- references 内部再链 reference → 提到主文件
- deterministic 解析全用 AI 算 → 写脚本放 scripts/
- SKILL.md 内嵌多行脚本让 AI 复读 → 抽到 scripts/，主文件只引用路径
- hook command 字段内嵌多行 Python / shell → 抽到 scripts/，hook 只 `python <path>` 调用
- 脚本散在 skill 根目录 → 全部归入 `scripts/` 一级子目录
- 关键阻断只靠 AI 自觉 → 加 PreToolUse hook
- skill 里硬编码外部 API → 走 MCP server
