---
name: git-safety-workflow
description: Use when reviewing local git changes, staging, committing, preparing PRs, handling dirty working trees, separating user edits from agent edits, or checking whether files belong to the current task.
---

# Git Safety Workflow

## 目标

在脏工作区内只处理当前任务相关改动，保护用户已有工作。

## 适用范围

优先用于：

- 用户要求提交、暂存、整理 diff、创建 PR
- 工作区已有未提交改动
- 需要判断哪些文件属于当前任务
- 同一文件里混有用户改动和本次改动

## 强制流程

### 1. 先看状态

提交或暂存前必须检查：

- `git status`
- staged 和 unstaged diff
- untracked files
- 最近提交风格

不要只看自己刚改的文件。

### 2. 分类改动

把改动分成：

- 本次任务相关
- 用户已有改动
- 生成产物
- 敏感文件或环境文件
- 不确定归属

不确定归属时，不擅自暂存。

### 3. 暂存和提交

规则：

- 只暂存相关文件
- 不提交 `.env`、密钥、凭据、临时日志、缓存
- 提交信息说明为什么改
- 不跳过 hooks
- 不擅自 amend
- 不擅自 push

### 4. 风险操作门

以下操作只有用户明确批准才可执行：

- `git reset --hard`
- 强制 push
- 删除未知文件
- 覆盖用户改动
- rebase/amend 已推送提交

## 检查门

以下情况不得提交：

- 没看 staged 和 unstaged diff
- untracked 文件未分类
- 有疑似密钥或环境文件
- 提交包含不相关格式化
- hooks 失败但仍声称成功

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| “我顺便提交了” | 只有用户要求提交才提交 |
| “这些改动都相关” | 按文件列出归属依据 |
| “先 reset 一下” | 说明风险并等待明确批准 |
| “hook 有点问题先跳过” | 修 hook 问题或请用户批准跳过 |
| “push 一下” | 用户明确要求 push 后再执行 |

## 输出格式

```markdown
Git：
- 相关改动：
- 未纳入改动：
- 敏感文件检查：
- 提交/暂存结果：
- 风险：
```
