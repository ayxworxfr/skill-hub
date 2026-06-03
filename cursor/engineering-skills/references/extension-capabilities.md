# 扩展能力（Scripts / Hooks / Plugins / 其他）

写 skill 不止能写 markdown。Claude Code 提供一组扩展能力，**用对了 skill 强 10 倍**。本文回答两个问题：每种能力是什么，什么时候该用。

## 全景图

```
┌────────────────────────────────────────────────────────────┐
│                       Plugin（容器）                       │
│  bundle 一组扩展，通过 marketplace 安装/分发                │
│  .claude-plugin/plugin.json + marketplace.json             │
│  ┌──────────┬──────────┬──────────┬──────────┬──────────┐ │
│  │  Skills  │ Commands │  Hooks   │  Agents  │   MCP    │ │
│  │ 知识/流程 │ /xxx 命令│ 生命周期 │ 子 Agent │ 外部接入 │ │
│  └──────────┴──────────┴──────────┴──────────┴──────────┘ │
└────────────────────────────────────────────────────────────┘
                              ↑
                Skills 内部还能用：
                - scripts/   可执行脚本（deterministic）
                - references/ 按需加载文档
                - assets/    模板/静态资源
                - 动态注入   skill 里写 !`cmd` 内联命令输出
```

## 一、Scripts（脚本）

### 是什么

Skill 目录下 `scripts/` 中的可执行文件（Python / Bash / Node / 任何能在运行环境执行的语言）。AI 会按 SKILL.md 指引调用脚本，把脚本输出读进上下文。

### 何时用（决策核心）

**判定准则**：能用代码 deterministic 解决的，**绝不让 AI 自己用 token 算**。

| 任务类型 | 用 markdown 让 AI 处理 | 用 script 处理 |
|---|---|---|
| 解析结构化数据（JSON/CSV/YAML） | ❌ AI 容易格式漂移 | ✅ 一行 jq / pandas |
| 排序、统计、计数 | ❌ 大数据量出错 | ✅ 100% 准确 |
| 文件批量改名/格式化 | ❌ 不可重复 | ✅ 幂等 |
| 跑测试/lint/typecheck | ❌ AI 编命令 | ✅ 项目脚本 |
| PDF/图片/二进制处理 | ❌ token 爆炸 | ✅ 标准库 |
| 计算 hash/diff/字符数 | ❌ AI 估计 | ✅ 精确 |
| 校验 schema/规范 | ❌ AI 漏检 | ✅ 必中 |
| 业务判断、设计取舍 | ✅ AI 强项 | ❌ 写死了 |
| 行文/解释/推理 | ✅ AI 强项 | ❌ 不灵活 |

### 收益（对照 AI 自算）

- **稳定性**：相同输入 → 相同输出，无随机偏差
- **token 成本**：脚本输出 1KB；AI 自己生成相同结果可能消耗 5K-20K token
- **速度**：本地脚本毫秒级；AI 推理秒级
- **可验证**：脚本可以单独跑、单元测试

### 怎么写

```
my-skill/
├── SKILL.md
└── scripts/
    └── extract_form_fields.py      # 显式调用
```

SKILL.md 中显式指引 AI 调用：

```markdown
### Step 2: 提取字段

执行：

\`\`\`bash
python scripts/extract_form_fields.py <pdf_path>
\`\`\`

脚本输出 JSON 数组，每个元素含 `name`, `type`, `required` 三字段。
读取后再做下一步。
```

### 必备元素

- 脚本路径在 SKILL.md 显式标出，不让 AI 猜
- 列出依赖包（`requirements.txt` 或 SKILL.md 里写 `pip install ...`）
- 给出输入/输出契约（参数 / 返回格式）
- 失败处理路径（脚本 exit 非 0 时 AI 怎么办）
- 跨平台时注意 Windows / Unix shell 差异

### 目录规范（强制）

**运行逻辑放 `scripts/` 一级子目录，SKILL.md 和 hook command 只引用路径，不内联超过 3 行的执行逻辑。**

| 内容类型 | 放在哪 | 怎么引用 |
|---|---|---|
| 一次性 shell 调用（≤1 行） | SKILL.md / hook command 内联 | 直接写 |
| 多行 Python / shell 解析、判断、循环 | `scripts/<name>.{py,sh}` | SKILL.md 链接 + 命令行调用 |
| 跨多个 skill 复用的工具 | 项目根 `scripts/` 或独立 plugin | 显式路径 |
| hook 阻断逻辑 | `<skill>/scripts/<name>.py` | settings.json 里 `command` 调用 |

强制理由：

- SKILL.md 嵌脚本 = AI 复读脚本浪费 token + 用户改逻辑要改两处
- JSON 内嵌多行 Python = 转义地狱 + 不可调试 + 不可单测
- 脚本独立 = 可 `python scripts/foo.py < fixture.json` 单独跑，可单测，可加白名单

### 反模式

- 在 SKILL.md 里贴 50 行 Python 让 AI 复读 → 应该放 `scripts/foo.py` 然后调用
- 把多行 Python / shell 内联到 hook command 字段 → 抽到 `scripts/`，hook 只调用
- 脚本散在 skill 根目录而非 `scripts/` 子目录 → 不符合 Anthropic 文件结构约定
- 脚本依赖外部 API key 但没在 SKILL.md 说明 → 必中失败
- 脚本写死路径不接受参数 → 不可复用

## 二、Hooks（生命周期钩子）

### 是什么

挂在 Claude Code 生命周期事件上的 shell 命令 / HTTP / Prompt / Agent。**不是 skill 的一部分**，但可以在 plugin 里 bundle，或者用 skill 引导用户配置。

配置位置：`.claude/settings.json`（用户级）或 plugin 里的 `hooks/` 目录。

### 12 个生命周期事件

| 事件 | 触发时机 | 是否能 block |
|---|---|---|
| `Setup` | `--init-only` 或维护模式启动 | 否 |
| `SessionStart` | 会话开始 | 否（可注入上下文） |
| `UserPromptSubmit` | 用户输入提交，到达 AI 之前 | ✅ |
| `UserPromptExpansion` | 用户输入是 slash 命令时展开 | 否 |
| `PreToolUse` | 工具调用之前 | ✅（exit 2） |
| `PermissionRequest` | 工具需要权限 | ✅ |
| `PostToolUse` | 工具调用之后（成功） | 否 |
| `PostToolUseFailure` | 工具调用失败 | 否 |
| `Notification` | 需要通知用户 | 否 |
| `PreCompact` / `PostCompact` | 上下文压缩前后 | 否 |
| `Stop` | AI 准备结束 | ✅（强制继续） |
| `SessionEnd` | 会话结束 | 否 |

### 退出码协议

- `0`：放行
- `1`：警告但继续（stderr 进日志）
- `2`：**阻断**（PreToolUse 阻止工具，Stop 强制继续）

### 何时用

| 场景 | 用 hook | 理由 |
|---|---|---|
| 阻止 AI 写敏感文件（`.env` / `package-lock.json`） | ✅ PreToolUse | exit 2 = 硬阻断，不靠 AI 自觉 |
| Edit 后自动跑 prettier | ✅ PostToolUse | 100% 命中 |
| 提交前强制跑测试 | ✅ Stop hook | 防止"已完成"的偷懒 |
| 操作敏感工具时音/视觉通知 | ✅ Notification | 用户感知 |
| 注入 git diff 到上下文 | ✅ SessionStart | 自动而非手动 |
| 写在 SKILL.md 里的"应该这样做"规则 | ❌ 用 skill | hook 不传达知识 |
| 业务判断、设计取舍 | ❌ 用 skill / AI | hook 是 deterministic 闸 |

### 简单示例

`.claude/settings.json`：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [{
          "type": "command",
          "command": "python3 -c \"import json,sys; d=json.load(sys.stdin); p=d.get('tool_input',{}).get('file_path',''); sys.exit(2 if any(x in p for x in ['.env','.git/']) else 0)\""
        }]
      }
    ]
  }
}
```

### Hook vs Skill

| 维度 | Skill | Hook |
|---|---|---|
| 触发方式 | AI 看 description 决定 | 系统在事件上必触发 |
| 内容形式 | markdown 知识 | 可执行命令 |
| 是否能阻断 | 靠 AI 遵守 | 退出码硬阻断 |
| 适合表达 | "怎么思考" | "怎么过闸" |
| 失效率 | 取决于触发激活率 | 100%（除非 hook 本身错） |

**核心区别**：skill 是建议（probabilistic），hook 是闸（deterministic）。设计 skill 时如果某条规则"必须严格执行"，问自己能不能转成 hook。

### 在 skill 里引导 hook

skill 不能直接装 hook，但可以：

```markdown
## 配置建议

本 skill 推荐配合以下 hook 使用，确保关键约束硬阻断：

在 `.claude/settings.json` 加：

\`\`\`json
{ ... }
\`\`\`

或装成 plugin（含 hook）：见下文 Plugin 章节。
```

## 三、Plugins（插件容器）

### 是什么

把 skills + commands + hooks + agents + MCP servers 打包成一个可分发单元。用 marketplace 安装：

```
/plugin marketplace add https://github.com/foo/bar
/plugin install my-tool@bar
```

### 目录结构

```
my-plugin/
├── .claude-plugin/
│   └── plugin.json            # 必需：name, version, description
├── skills/                    # 多个 skill 目录
│   └── my-skill/SKILL.md
├── commands/                  # slash 命令
│   └── deploy.md
├── hooks/                     # 钩子脚本
│   └── pre-commit.sh
├── agents/                    # 子 agent 定义
│   └── reviewer.md
├── .mcp.json                  # MCP server 配置
└── README.md
```

`marketplace.json`（仓库根 `.claude-plugin/marketplace.json`）：

```json
{
  "name": "my-marketplace",
  "plugins": [
    {
      "name": "my-tool",
      "source": "./plugins/my-tool",
      "description": "..."
    }
  ]
}
```

### 何时用

| 场景 | 用 plugin |
|---|---|
| 单个 skill 个人用 | ❌ 直接放 `~/.claude/skills/` |
| 一组 skills + 配套 hooks 给团队用 | ✅ 一键安装一致 |
| 含 MCP server + 私有 agent | ✅ 必须打包 |
| 跨项目复用且要版本控制 | ✅ pinned version |
| 公开发布到社区 | ✅ marketplace |

### 收益

- **原子性**：一次安装拿到全部相关能力
- **版本化**：plugin.json 的 `version` 字段，pinned 后只接收明确升级
- **隔离**：plugin 里的 hooks 不污染用户全局 settings.json
- **分发**：git URL 即装即用

### 在 skill 设计阶段考虑

写 skill 时如果发现：

- 需要配套 hook 强阻断 → 考虑做成 plugin
- 需要外部 API（DB / Slack / Linear） → 配 MCP server，做成 plugin
- 团队多人用 → 做成 plugin 走 marketplace

否则单 skill 即可。

## 四、Subagents（子 Agent）

### 是什么

`.claude/agents/<name>.md`，独立的 Claude 实例，自带：

- 独立 system prompt
- 工具限制（`allowed-tools`）
- 模型选择（Haiku / Sonnet / Opus）
- 隔离 context 窗口

### 何时用

| 场景 | 用 subagent |
|---|---|
| code review 用 Haiku 省钱 | ✅ 60% 成本降低 |
| 跑只读分析不污染主对话 | ✅ context 隔离 |
| 并行任务（多个 review 同时跑） | ✅ Skills 不能并行 |
| 受限工具（read-only） | ✅ 安全 |
| 通用知识/流程 | ❌ 用 skill |

### 与 skill 关系

- subagent 可以加载 skill：subagent 里写 `Skills: [my-skill]`，激活时一并加载
- skill 可以触发 subagent：通过 `Agent` 工具派发给指定 subagent
- 二者正交，不冲突

## 五、MCP Servers（外部接入）

### 是什么

Model Context Protocol。把外部数据 / API / 数据库暴露成 Claude 可调的 tool。

### 何时用

| 场景 | 用 MCP |
|---|---|
| 查 PostgreSQL / Redis | ✅ |
| 调 Slack / Linear / Jira | ✅ |
| 跨会话状态持久化 | ✅ |
| 本地文件读写 | ❌ 用 Read/Write/Bash |
| 一次性 shell 调用 | ❌ 用 Bash |

### 与 skill 关系

skill 可以在 SKILL.md 里引用 MCP 工具：

```markdown
### Step 2: 拉取数据

调用 MCP 工具 `postgres__query`：

\`\`\`
SELECT ... FROM ...
\`\`\`
```

skill 描述工作流，MCP 提供能力，二者互补。

## 六、Slash Commands（斜杠命令）

### 是什么

`.claude/commands/<name>.md`，用户输入 `/<name>` 直接执行。frontmatter 同 skill。

### 与 skill 区别

| 维度 | Skill | Command |
|---|---|---|
| 触发方式 | AI 自动判断 | 用户显式输入 `/foo` |
| 适合 | 通用知识、AI 自主选择 | 用户主动启动的固定流程 |
| 对话感 | 隐式 | 显式 |

`/review` `/deploy` `/migrate` 类用户主动触发的固定流程 → 用 command；"什么时候该 review、怎么 review" 类背景知识 → 用 skill。

## 七、Dynamic Context Injection（动态注入）

### 是什么

skill 内容里写 `!`命令``，加载时被替换成命令输出（在 AI 看到内容之前）。

```markdown
## 当前上下文

最近改动：

!`git diff HEAD --stat`

进行中的分支：

!`git branch --show-current`
```

### 何时用

- skill 需要"当前 git 状态"/"当前文件列表"等动态信息
- 比让 AI 自己跑命令更稳：保证一定执行、保证内容在上下文最前面
- 用作"reference 自动加载"的轻量替代

### 注意

- 命令延迟会拖慢 skill 加载
- 命令失败会让 skill 内容残缺
- 不要用慢命令（>2 秒）

## 八、决策树：我的 skill 应该用哪些能力？

```text
用户提需求
  │
  ▼
1. 是不是 deterministic 计算/解析？
  ├─ 是 → 写 scripts/，让 AI 调用
  └─ 否 → 继续
  │
  ▼
2. 有没有"必须严格执行不能漏"的硬规则？
  ├─ 是 → 配套 hook（PreToolUse/PostToolUse/Stop），可能要做成 plugin
  └─ 否 → 继续
  │
  ▼
3. 需不需要外部数据/系统？
  ├─ 是 → 配套 MCP server，做成 plugin
  └─ 否 → 继续
  │
  ▼
4. 用户会不会主动用 / 命令触发？
  ├─ 是 → 同时做一个 slash command
  └─ 否 → 继续
  │
  ▼
5. 团队多人用 / 跨项目复用？
  ├─ 是 → 打包成 plugin 发 marketplace
  └─ 否 → 单 skill 放 ~/.claude/skills/
  │
  ▼
6. skill 需要动态上下文（git/进程状态）？
  ├─ 是 → 用 !`cmd` 动态注入
  └─ 否 → 纯 markdown skill 即可
```

## 九、能力组合的反模式

| 反模式 | 后果 | 替代 |
|---|---|---|
| 把脚本逻辑全写在 SKILL.md 里让 AI 复读 | token 浪费、不稳定 | 放 scripts/ 调用 |
| hook command 字段内联多行 Python / shell | 转义地狱 + 不可单测 + 不可调试 | 抽到 `<skill>/scripts/<name>.py`，hook 只调用 |
| 脚本散在 skill 根目录而非 `scripts/` | 不符合 Anthropic 文件结构 | 全部归入 `scripts/` 一级子目录 |
| 用 skill 表达硬规则（"绝不允许 X"） | 取决于 AI 自觉 | 加 PreToolUse hook |
| 单 skill 散在多个目录，让团队各自配 | 漂移、不一致 | 打包 plugin |
| 在 hook 里写 200 行业务逻辑 | 不可调、不可观测 | 复杂逻辑回 skill 让 AI 处理 |
| skill 里硬编码外部 API 调用 | 凭空调用失败 | 配 MCP server |
| 给 AI 自己重新实现已有 CLI 工具 | 不准 | 调命令、读输出 |

## 十、能力选择检查门

写 / 改 skill 时必须答：

- [ ] 流程里有没有 deterministic 步骤可以写脚本？
- [ ] 有没有硬规则可以转成 hook？
- [ ] 需不需要外部数据要 MCP？
- [ ] 是单 skill 还是要打包 plugin？
- [ ] 用户是主动触发（command）还是 AI 自动选（skill）？
- [ ] 已有脚本 / hook 是否都放在 `scripts/` 子目录？SKILL.md 和 hook command 只引用路径，没复读多行执行逻辑？

任一可以用更稳能力却用了纯 markdown 的，标 **Warn** 并在输出里写为什么不用。脚本散主目录或 hook 内联多行逻辑直接 **Block**。
