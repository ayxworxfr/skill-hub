# 结构先行：动笔前的文件预算

写 SKILL.md 最常见的失败：**先把所有内容塞进主文件，最后说"以后再拆"**。"以后"不会到来——主文件结构已被污染，注意力锚点错位，全文要重写。

本 reference 把"决定文件布局"前置到下笔前。**没出文件预算表禁止开写。**

## 1. 标准目录形态

```
skill-name/
├── SKILL.md          # 入口 + 路由 + 共用骨架（≤300 行目标，≤500 硬上限）
├── references/       # 按需加载的细则（一级目录，不嵌套）
│   ├── topic-a.md
│   └── topic-b.md
├── scripts/          # 确定性可执行脚本（可选）
│   └── helper.py
└── assets/           # 模板 / 静态资源 / 空白骨架（可选）
    └── template.md
```

铁律：

- `references/` 只能从 `SKILL.md` 直接链接
- 不允许 reference A 链 reference B（Anthropic 明确禁止 deeply nested references）
- `scripts/`、`assets/` 路径在 SKILL.md 里用 `[name](scripts/x.py)` 引用
- 所有路径用正斜杠

## 2. 主文件 vs references vs scripts vs hooks 决策

| 内容类型 | 去向 | 判定 |
|---|---|---|
| 入口路由 / 子模式判定 / Core Principle | **主 SKILL.md** | 必须始终在内存 |
| 共用骨架（适用所有子模式的步骤纲领） | **主 SKILL.md** | 但只留摘要 + 链接 |
| Final Gate / 禁止输出 | **主 SKILL.md** | 输出前最后一道关 |
| 子模式专属流程 | **references/<sub-mode>.md** | 一个子模式一个文件 |
| > 100 行的细则 | **references/topic.md** | 包含 TOC |
| > 30 行的表格 | **references/topic.md** | 主文件留摘要 |
| 长示例 / 完整模板 / 输出骨架 | **references/skeleton.md** 或 **assets/** | 主文件留链接 |
| 确定性计算 / 解析 / 批量操作 | **scripts/** | AI 调用比 AI 自己算稳 |
| 必须严格执行不能漏的硬约束 | **hooks**（PreToolUse / Stop） | markdown 拦不住 |
| 需要外部数据 / API | **MCP server** | skill 只编排不直连 |

**核心判定**：能 deterministic 解决的不让 AI 自己算；必须严格的不靠 AI 自觉。

## 3. 文件预算表（动笔前必填）

写任何 `## ` 章节正文之前，先在对话里输出：

```markdown
## 文件预算

| 文件 | 角色 | 预估行数 | 内容范围（≤3 句） | 留主 / 拆出的理由 |
|---|---|---|---|---|
| SKILL.md | 入口 + 路由 + 共用骨架 | 180 | Core Principle / 子模式判定 / 7 步流程摘要 / Final Gate / 禁止输出 | 必须始终在内存 |
| references/foo.md | new 子模式专属流程 | 120 | new 模式 6 步详细 + 输出片段 | 子模式专属，不污染 revise/audit |
| references/bar.md | 长表细则 | 90 | 5 模式落点逐项展开 | 表 >30 行 |
| scripts/check.py | 行数 / 字符数 / 链接核对 | 60 | 输入 SKILL.md 路径，输出 PASS/FAIL 列表 | 确定性计算，AI 算容易漏 |
```

### 预算硬约束

| 信号 | 立即处理 |
|---|---|
| 主 SKILL.md 估算 > 300 行 | 再拆，不允许"先写写看" |
| 子模式专属知识塞进主文件 | 拆到 `references/<sub-mode>.md` |
| 单一主题细则 > 100 行 | 独立 reference + 文首加 TOC |
| 表格 > 30 行 | 独立 reference |
| 完整代码 / 长模板 inline | 拆到 reference 或 assets |
| 同一段内容 ≥2 处出现 | 留一份，其它链接过去 |
| 多个 check 列表互相覆盖 | 合并为单层 Final Gate |

## 4. 写入顺序（防注意力污染）

按这个顺序写，**不允许颠倒**：

1. 在对话里**输出文件预算表**给用户/自己确认
2. 创建所有 references 的**骨架**（标题 + 章节大纲，正文可空）
3. 写主 SKILL.md：每个步骤摘要 + 用 `[X.md](references/X.md)` 显式链接
4. 回填 references 正文
5. 写 scripts（如有），注明依赖、输入输出契约
6. 主文件实测 `wc -l`，超 300 立刻回到 1 重新分配

不允许：

- 主文件先写完一长串再回头拆（注意力已经污染）
- 写到一半才"想起"应该拆（结构已经塌）
- 占位 reference（"详见 X 文档"但 X 不存在）
- 主文件用"参见某段"模糊指向，不给具体链接

## 5. 命名

### name 字段（= 目录名）

- ≤ 64 字符，`a-z0-9-` 三类字符
- **动名词形式**：`engineering-skills`、`processing-pdfs`、`debugging`，**不**用 `engineer-skill`、`process-pdf`、`debug`
- 必须与目录名一致
- 禁止包含 `anthropic` / `claude`

### reference 文件名

- 短语 + 名词，描述内容主题：`anthropic-spec.md`、`design-patterns.md`、`audit-checklist.md`
- 不用 `details.md`、`extra.md`、`misc.md` 这类无信号名

### scripts 文件名

- 描述动作：`check-frontmatter.py`、`count-lines.sh`
- 入口脚本必须可独立运行（含 shebang / 用法注释）

## 6. 进阶：`progressive disclosure` 工作机理

Anthropic 的 SKILL.md 工作原理：

1. 启动时 skill 描述（仅 description 字段，~1KB）注入 system prompt
2. 任务命中触发条件 → SKILL.md **全文**读入 context
3. SKILL.md 中 markdown 链接的 references → **按需** 才读

含义：

- description 决定**是否激活**（必须含触发短语）
- SKILL.md 决定**主流程怎么走**（保持可扫描，避免一次塞太多）
- references 撑**细节不耗常驻 context**（细节进来只在用到时）

主文件长 ≠ skill 强：长主文件挤压所有用户对话的 token 预算。让 references 撑细节，主文件只留路由 + 决策骨架。

## 7. 反模式速查

| 反模式 | 替代 |
|---|---|
| "这个 skill 简单，一个文件够了" | 仍要写文件预算表，确认估算确实 ≤200 行 |
| "先把内容写完整再拆" | Step 1 文件预算先行 |
| "细节都堆主文件方便看" | 细节去 references，主文件保持可扫描 |
| "ref A 引 ref B 链下去更结构化" | 禁止两跳；扁平化或把内容上提到主文件 |
| "脚本以后再写" | 决策树命中 scripts → 当前 skill 内同步落地 |
| "动名词大概意思就行" | `processing-X` / `writing-Y`，不用 `process-X` |

## 8. 实例：本 engineering-skills 自身的预算（参考）

| 文件 | 角色 | 行数 | 理由 |
|---|---|---|---|
| SKILL.md | 入口 + 7 步路由 + Final Gate + 禁止输出 | ~180 | 主流程必须常驻 |
| anthropic-spec.md | 规范字段 / 限额 / 反例 | ~150 | 长规范细则 |
| design-patterns.md | 5 模式逐项展开 | ~250 | 大表格 + 详细示例 |
| skill-skeletons.md | 4 类骨架模板 | ~160 | 分类内容 |
| extension-capabilities.md | scripts/hooks/MCP/plugin 决策 | ~440 | 跨多能力的长决策 |
| audit-checklist.md | audit 子模式核对项 | ~230 | 子模式专属 + 长 checklist |
| structure-planning.md | 本文件，结构先行细则 | ~150 | 子主题独立 |
| output-skeleton.md | 输出模板 | ~70 | 长模板 |

主文件占总篇幅 < 12%，全部细节按主题拆 references，符合 progressive disclosure。
