---
name: git-safety
description: Protects user changes and repo history during git operations by enforcing per-file diff review, sensitive-file detection, worktree isolation for high-risk tasks, and explicit authorization for destructive actions. Use when the user says "commit"/"提交"/"暂存"/"push"/"PR"/"整理 diff"/"清理工作区", when the working tree has unrelated changes, when multiple agents work in parallel, or before any stage/commit/push action.
---

# Git Safety

## Core Principle

保护用户改动和仓库历史。AI 只处理当前任务相关 diff，高风险任务优先隔离，提交前必须逐文件确认、跑验证、防泄密。**不擅自暂存、不擅自提交、不擅自 push、不批量 add、不跳 hook、不覆盖归属不明的改动。**

## 适用范围

优先用于：

- 用户要求提交、暂存、整理 diff、创建 PR、推送
- 工作区已有未提交改动需要分类
- 同一文件里混有用户改动和本次改动
- 多个 agent/session 并行工作
- 任务涉及依赖、lockfile、配置、生成文件、迁移文件、入口文件

不要用于：

- 纯代码改动本身：用 `building` / `debugging` / `refactoring`
- 验证策略：用 `verifying`
- 前端布局：用 `designing-frontend`

## 强制流程

### 1. 状态侦察

提交、暂存或改动前必须收集：

- `git status`
- staged diff
- unstaged diff
- untracked files
- 当前分支和 upstream 状态
- 最近提交信息风格

不要只看自己刚改的文件。看到意外改动时先归类，不要覆盖。

### 2. Worktree 隔离判断

以下情况优先建议或使用独立 worktree：

- 主工作区已有用户未提交改动
- 任务跨多个文件或耗时较长
- 多个 agent/session 并行
- 任务会运行格式化、代码生成、迁移、依赖安装
- 改动风险高，失败后需要整体丢弃

Worktree 规则：

- 每个 agent/session 使用独立 branch + worktree
- worktree 放在 repo 外，或放在已被 ignore 的目录
- 不让多个 worktree 并行修改同一 lockfile、核心配置、入口文件
- 删除 worktree 用 `git worktree remove`，不用 `rm -rf`
- 意外删除目录后，运行 `git worktree prune` 清理元数据

### 3. 分类改动

把所有改动分成：

- 本次任务相关
- 用户已有改动
- 生成产物
- 依赖和 lockfile
- 敏感文件或环境文件
- 不确定归属

不确定归属时，不暂存、不删除、不覆盖，先说明并询问。

### 4. 逐文件审查 diff

暂存前必须逐文件确认：

- 文件为什么属于当前任务
- 是否包含用户原有改动
- 是否包含无关格式化
- 是否包含生成产物
- 是否包含密钥、token、私钥、`.env`、本地路径、调试日志

禁止用"看起来都相关"替代逐文件判断。

### 5. 中段自检

暂存前确认：

- [ ] staged + unstaged + untracked 三类都看过
- [ ] 每个待暂存文件都能说出归属理由
- [ ] 已检查疑似敏感文件
- [ ] 已识别用户原有改动并保留

任一未通过 → 回 Step 1-4 补，禁止暂存。

### 6. 选择性暂存

默认按明确文件路径暂存。

禁止使用：

- `git add .`
- `git add -A`
- `git commit -am ...`

除非用户明确要求提交整个工作区，并且已经逐文件确认所有改动都属于当前任务。

### 7. Hook、验证和提交

提交前必须：

- 跑或确认相关验证（按 `verifying` skill 选最小有效验证）
- 不使用 `--no-verify`，除非用户明确批准
- hook 失败时先读错误并修复，不机械重试
- 本地 hook 通过不等于 CI 通过；关键改动仍需 CI/远端检查
- 提交信息说明为什么改，不只说改了什么

### 8. 推送和 PR

规则：

- 不擅自 push
- 不 force push，除非用户明确要求；禁止 force push 到 main/master
- 不擅自 amend 已推送提交
- PR 前确认分支、diff、验证结果、敏感文件、未纳入改动

### 9. Final Gate

输出前确认：

- [ ] staged/unstaged/untracked 已分类并显式说明
- [ ] 每个 staged 文件都有归属理由
- [ ] 敏感文件检查已完成
- [ ] hook/验证已跑或显式说明未跑原因
- [ ] 没有 force push、--no-verify、批量 add 等未授权操作
- [ ] 没有触发"禁止输出模式"任一行

任一未通过不得声称完成。

## 敏感文件规则

不得提交：

- `.env`、`.env.*` 中的真实密钥
- 私钥、证书、token、cookie、凭据
- 本地数据库、缓存、日志、临时导出
- IDE 私有状态、机器路径、个人配置

用户明确要求提交疑似敏感文件时，先警告并等待二次确认。

## 并发冲突门

多个 agent/session/branch 并行时：

- 先确认文件域是否重叠
- 依赖变更和 lockfile 变更必须串行
- 核心配置、迁移文件、公共类型、入口文件不要并行改
- 合并前检查目标分支是否更新
- 发现重叠文件时，序列化任务，不靠最后 merge 碰运气

## 风险操作门

以下操作必须用户明确批准才执行：

- `git reset --hard`
- 强制 push
- 删除未知文件
- 覆盖用户改动
- rebase/amend 已推送提交
- 跳过 hooks (`--no-verify`)
- 清理 worktree 或删除分支
- `git clean -f`

## 配套 hook 配置（推荐）

上面的硬禁止（批量 add、`--no-verify`、force push、`reset --hard` 等）靠 AI 看 markdown 自觉遵守。要彻底兜底，配 PreToolUse hook 在执行前拦下危险 Bash 命令。

阻断逻辑写在 [scripts/check_dangerous_git.py](scripts/check_dangerous_git.py)，hook 只调用脚本。在 `.claude/settings.json` 加：

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [{
          "type": "command",
          "command": "python3 <skills-dir>/git-safety/scripts/check_dangerous_git.py"
        }]
      }
    ]
  }
}
```

把 `<skills-dir>` 替换为本仓库实际路径（如 `D:/.cursor/skills`）。脚本约定：

- 输入：stdin 读取 Claude Code 传入的 tool_use JSON
- 输出：命中危险 pattern → stderr 写消息 + exit 2；否则 exit 0
- 阻断规则集：脚本顶部 `DANGEROUS_PATTERNS` 列表，扩展或加白名单直接改这里

适配说明：

- Windows 下把 `python3` 换成 `python`
- 用户明确批准某次 force push / `--no-verify` 时，临时注释 hook 或在 `DANGEROUS_PATTERNS` 里加白名单
- hook 不传达知识，只做硬阻断；规则解释仍由本 skill 承担

## 检查门

以下情况不得提交：

- 没看 staged 和 unstaged diff
- untracked 文件未分类
- 用批量暂存但未逐文件确认
- 有疑似密钥或环境文件
- 提交包含不相关格式化
- hooks 或验证失败但仍声称成功
- 工作区仍有不确定归属改动

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "我顺便提交了" | 只有用户要求才提交 |
| "这些改动都相关" | 按文件列出归属依据 |
| "先 add 全部" | 逐文件审查后按路径暂存 |
| "hook 有点问题先跳过" | 修 hook 问题或请用户批准跳过 |
| "push 一下" | 用户明确要求 push 后再执行 |
| "worktree 直接删了" | 用 `git worktree remove` 或说明 prune |
| "应该没敏感信息" | 列出已检查的文件和模式 |
| "verify 后面再补" | 提交前补完，或显式说明未跑原因 |

## 输出格式

```markdown
## Git 状态

- 当前分支：
- upstream：
- staged：<文件清单 + 归属>
- unstaged：<文件清单 + 归属>
- untracked：<文件清单 + 归属>

## Worktree/隔离判断

- <用了独立 worktree / 不需要 / 已说明原因>

## 敏感文件检查

- <检查范围 + 结论>

## 验证/hook

- 命令：
- 结果：

## 提交/暂存结果

- <动作 + 影响范围>

## 风险

- <未纳入改动 / 待确认归属 / 剩余风险，没有写"无"）
```
