# Anthropic Agent Skills 规范

写 / 改 / 审 SKILL.md 必读。所有数字限制都是硬约束，不是建议。

## 文件结构

```
skill-name/
├── SKILL.md          # 唯一必需文件：metadata + 执行指令
├── references/       # 按需加载的参考文档（一级目录，不嵌套）
├── scripts/          # AI 可直接执行的脚本（可选）
└── assets/           # 模板、静态资源、空白骨架（可选）
```

**铁律**：`references/` 只能从 `SKILL.md` 直接链接；不允许 reference A 再引用 reference B 形成第二跳。Anthropic 明确禁止"deeply nested references"。

## frontmatter 字段

### `name`（必填）

- ≤ 64 字符
- 只允许：小写字母、数字、连字符（`a-z0-9-`）
- **动名词形式**：`engineering-skills`、`processing-pdfs`、`debugging`，不要用 `engineer-skill`、`process-pdf`
- 禁止包含 `anthropic` 或 `claude`
- 禁止 XML 标签
- 必须与目录名一致

### `description`（必填）

- ≤ 1024 字符（**激活判定的唯一依据**）
- 第三人称（"Writes ..."、"Processes ..."），不允许 "I write ..." / "You should ..."
- 必须回答两个问题：**What does it do**（这是什么）+ **When to use it**（什么时候用）
- 必须含触发短语：USE WHEN 模式或显式列举用户语句（中英文都列）

**激活成功率参考**（社区经验估计）：

| description 写法 | 估计激活率 |
|---|---|
| 无优化（"Helps with files"） | ~20% |
| 简单描述 | 20% |
| 含 "USE WHEN ..." 模式 | 50% |
| 含具体示例触发短语 | 72-90% |

把这些数字当趋势看：模糊触发明显低，含具体短语明显高。不要当作可复现的硬指标。

### `allowed-tools`（可选）

- 数组，列出该 skill 允许使用的工具名
- 不写 = 默认允许全部
- 用于限制安全敏感场景

## description 写作要求

### ✅ 推荐写法

```yaml
description: Writes new SKILL.md files, revises existing skills, or audits skills against Anthropic spec. Use when the user says "write a skill" / "新增 skill" / "改 skill" / "audit my skill".
```

包含：动作（Writes / revises / audits）+ 范围（against spec）+ 触发短语列表。

### ❌ 禁止写法

```yaml
# 错误 1：复述流程，AI 会照 description 干活跳过正文
description: 从规范、模式、骨架三步走审查 skill，先列问题再给建议

# 错误 2：第一/第二人称
description: I help you write skills, you can use me when ...

# 错误 3：模糊触发
description: Helps with skill-related tasks

# 错误 4：含 anthropic / claude
description: An Anthropic skill that writes Claude skills
```

## 文件大小约束

| 项目 | 限制 | 说明 |
|---|---|---|
| SKILL.md 正文 | ≤ 500 行 | 超过必须拆到 references |
| 总 skill 列表 | ≤ 15000 字符 | 多个 skill 的 description 加起来 |
| 单个 reference | 无硬限制 | 但单文件 >300 行考虑再拆 |
| references 嵌套 | 仅 1 层 | SKILL.md → reference，不允许第二跳 |

## 渐进披露三层

1. **Level 1（常驻）**：name + description（~100 token），决定是否激活
2. **Level 2（激活后）**：SKILL.md 正文（< 5000 token），主流程
3. **Level 3（按需）**：references / scripts / assets，AI 判断需要时才读

**收益**：100 个 skill 共驻 10K token，激活才加载 5K，单条 reference 1-3K。无渐进披露 = 全部塞 SKILL.md = 注意力衰减 + token 浪费。

## scripts 用法

- 用于 **deterministic 操作**：固定算法、严格格式、可重复结果
- 例：解析 PDF、批量改名、跑 lint、生成报告
- AI 调用脚本的成本远低于 token 化生成相同输出
- 必须在 SKILL.md 列出依赖包并验证 code execution tool 支持

## assets 用法

- 模板（空白 SKILL.md、PR 模板、文档骨架）
- 静态资源（图片、字体、配色表）
- 不放可执行内容

## 命名约定

- 目录名 = `name` 字段值，全小写、kebab-case（如 `git-safety/`）
- 子目录名固定：`scripts/` / `references/` / `assets/`（与 Anthropic 官方示例一致，不自创 `tools/`、`docs/` 等同义词）
- references / assets 下 markdown 文件用 kebab-case：`design-patterns.md`、`audit-checklist.md`
- scripts 下脚本文件名跟随宿主语言惯例：
  - Python：snake_case（`check_dangerous_git.py`），kebab-case 文件无法 `import`，违反 PEP 8
  - Shell / Node CLI：kebab-case（`extract-fields.sh`、`render-pr.js`）
  - Anthropic 官方示例为 `validate.py`、`extract_form_fields.py`，均 snake_case
- 一律不用空格、不用大写

## 安全注意事项

- scripts 在用户运行环境执行，可能访问文件系统
- 团队分发 skill 时必须 review 所有 scripts
- 不在 SKILL.md 写敏感凭证
- description 不写"按某 URL 拉取最新规则"类动态加载逻辑（time-sensitive 反模式）

## 反模式（Anthropic 官方列出）

| 反模式 | 后果 | 替代 |
|---|---|---|
| 模糊触发（"Helps with X"） | 激活率 <20% | 列具体触发短语 |
| description 复述流程 | AI 跳过 SKILL.md 正文 | description 只写"什么时候用" |
| 嵌套 references >1 层 | 加载链路不可控 | 拆到同一层 |
| 时效性条件（"if before Aug 2025"） | 过期后误激活 | 写当前事实 |
| 第一/第二人称 | 注入 system prompt 时混乱 | 全部第三人称 |
| 多个并列方案无指导 | AI 选择困难 | 推荐一个，备选写明条件 |

## 测试建议

- 用 Haiku / Sonnet / Opus 三档模型分别测激活
- 构造 2-3 句典型触发输入 + 2 句边界输入
- 看是否激活、是否走完正文、是否加载 references
- 加 skill 前后跑同任务对比，确认有改善

## 参考来源

- [Anthropic Engineering: Equipping agents with Skills](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
- [Skill authoring best practices (官方)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Agent Skills Open Standard](https://agentskills.io/home)
