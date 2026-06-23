---
name: git-safety
description: Performs git operations safely: stage/commit/push/PR/diff cleanup. Use when the user says "commit"/"提交"/"暂存"/"push"/"PR"/"整理 diff"/"清理工作区", when the working tree has unrelated changes, when multiple agents work in parallel, or before any stage/commit/push action. Skip for:pure code editing without git intent.
---

# Git Safety

## Core Principle

保护用户改动和仓库历史。AI 只处理当前任务相关 diff，高风险任务优先隔离，提交前格式化 staged 文件、防泄密、写规范 commit message。**不擅自暂存、不擅自提交、不擅自 push、不批量 add、不跳 hook、不覆盖归属不明的改动。**

## 适用范围

优先用于：

- 用户要求提交、暂存、整理 diff、创建 PR、推送
- 工作区已有未提交改动需要分类
- 同一文件里混有用户改动和本次改动
- 多个 agent/session 并行工作

不要用于：

- 纯代码改动本身：用 [building](../building/SKILL.md) / [debugging](../debugging/SKILL.md) / [refactoring](../refactoring/SKILL.md)
- 验证策略：用 [verifying](../verifying/SKILL.md)

## 强制流程

### 1. 状态侦察

提交、暂存或改动前必须收集：

- `git status`
- staged diff
- unstaged diff
- untracked files
- 当前分支和 upstream 状态
- 最近提交信息风格（用于对齐 commit message 格式）

不要只看自己刚改的文件。看到意外改动时先归类，不要覆盖。

### 2. Worktree 隔离判断

满足**任一**条件时，优先建立独立 worktree：

- 主工作区已有用户未提交改动
- 任务跨多个文件或耗时较长
- 多个 agent/session 并行
- 任务会运行格式化、代码生成、迁移、依赖安装

详见 [worktree-isolation.md](references/worktree-isolation.md)，含建立/合并/清理规则和多 agent 并发冲突门。

### 3. 分类改动

把所有改动分成：

- 本次任务相关
- 用户已有改动（保留，不覆盖）
- 生成产物 / 格式化副产物
- 依赖和 lockfile
- 敏感文件或环境文件
- 不确定归属 → 先说明并询问，不暂存、不删除

### 4. 逐文件审查 diff

暂存前必须逐文件确认：

- 文件为什么属于当前任务
- 是否包含用户原有改动
- 是否包含密钥、token、私钥、`.env`、本地路径、调试日志

禁止用"看起来都相关"替代逐文件判断。

### 5. 中段自检

暂存前 checkbox 全过：

- [ ] staged / unstaged / untracked 三类都看过
- [ ] 每个待暂存文件都能说出归属理由
- [ ] 已检查疑似敏感文件（见安全规则）
- [ ] 已识别用户原有改动并保留

任一未通过 → 回 §1-4 补；禁止暂存。

### 6. 选择性暂存

默认按明确文件路径暂存。

禁止使用 `git add .` / `git add -A` / `git commit -am ...`，除非用户明确要求提交整个工作区并已逐文件确认。

### 7. Hook、格式化和提交

提交前必须：

- 跑格式化 hook（`scripts/format_staged.py` 或 hook 管理器）——只格式化 staged 文件，不动用户其他改动
- 跑或确认相关验证（按 [verifying](../verifying/SKILL.md) 选最小有效验证）
- 检查 commit message 格式（Conventional Commits），见 [commit-message.md](references/commit-message.md)
- 不使用 `--no-verify`，除非用户明确批准
- hook 失败时先读错误并修复，不机械重试

格式化 hook 配置（管理器三选 + lint-staged 模式）见 [hooks-setup.md](references/hooks-setup.md)。

### 8. 推送和 PR

规则：

- 不擅自 push
- 不 force push，除非用户明确要求；禁止 force push 到 main/master
- 不擅自 amend 已推送提交
- PR 前确认分支、diff、验证结果、敏感文件、未纳入改动

## 安全规则

**敏感文件**——不得提交：

- `.env`、`.env.*` 中的真实密钥；私钥、证书、token、cookie、凭据
- 本地数据库、缓存、日志、临时导出；IDE 私有状态、机器路径

用户明确要求提交疑似敏感文件时，先警告并等待二次确认。推荐配 secret 扫描 hook（gitleaks），见 [secret-scan.md](references/secret-scan.md)。

**风险操作**——必须用户明确批准才执行：

`git reset --hard` / 强制 push / 覆盖用户改动 / rebase/amend 已推送提交 / 跳过 hooks (`--no-verify`) / 清理 worktree 或删除分支 / `git clean -f` / 删除未知文件

危险命令由 `scripts/check_dangerous_git.py` 在 PreToolUse hook 自动拦截，hook 配置见下。

## 配套 hook 配置

将以下内容加入 `.claude/settings.json`，把 `<skills-dir>` 替换为本仓库路径：

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": "Bash",
      "hooks": [{"type": "command", "command": "python3 <skills-dir>/git-safety/scripts/check_dangerous_git.py"}]
    }]
  }
}
```

格式化和 secret 扫描推荐用 pre-commit 或 lefthook 管理，模板见：

- `assets/.pre-commit-config.yaml`（跨语言，推荐）
- `assets/lefthook.yml`（并行，追求性能）
- `assets/gitleaks.toml`（secret 扫描白名单）

## 质量门

输出前确认三件事（不重扫上面各节）：

1. **状态覆盖**：staged / unstaged / untracked 已分类显式说明；每个 staged 文件有归属理由；敏感文件检查已完成
2. **格式化与验证**：格式化 hook 已跑（或显式说明原因）；验证已跑或显式说明；commit message 符合 Conventional Commits 格式
3. **操作合规**：无 force push / `--no-verify` / 批量 add 等未授权操作；禁止输出表无触发

任一违规不得声称完成。

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "我顺便提交了" | 只有用户要求才提交 |
| "先 add 全部" / "这些改动都相关" | 逐文件审查后按路径暂存 + 列出归属依据 |
| "hook 有点问题先跳过" | 修 hook 问题或请用户批准跳过 |
| "push 一下" | 用户明确要求 push 后再执行 |
| "应该没敏感信息" | 列出已检查的文件和模式（或跑 gitleaks）|
| "格式化了整个项目" | 只格式化 staged 文件（lint-staged 模式）|

## 输出格式

```markdown
## Git 状态

- 当前分支：
- upstream：
- staged：<文件清单 + 归属>
- unstaged：<文件清单 + 归属>
- untracked：<文件清单 + 归属>

## Worktree/隔离判断

- <用了独立 worktree / 不需要 + 原因>

## 格式化与验证

- 格式化：<运行命令 + 结果>
- 验证：<命令 + 结果>
- commit message：<type(scope): description>

## 敏感文件检查

- <检查范围 + 结论（或 gitleaks 结果）>

## 提交/暂存结果

- <动作 + 影响范围>

## 风险

- <未纳入改动 / 待确认归属 / 剩余风险；没有写"无">
```
