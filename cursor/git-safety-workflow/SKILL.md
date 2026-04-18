---
name: git-safety-workflow
description: Handles git changes safely in a dirty working tree without disturbing unrelated user work. Use when preparing commits, reviewing local changes, staging files, or deciding which edits belong to the current task in a repository with existing uncommitted changes.
---

# Git Safety Workflow

## 目标

在存在脏工作区时，严格只处理当前任务相关改动。

## 工作流

### 1. 先确认工作区状态

- 查看未跟踪文件、已暂存改动、未暂存改动
- 识别哪些是本次任务相关，哪些不是
- 对不相关改动保持只读心态

### 2. 修改前的原则

- 不回滚用户已有改动
- 不覆盖看不懂的变化
- 如果同一文件里出现意外变更，先停下来确认

### 3. 提交前的原则

- 只暂存相关文件
- 提交信息说明“为什么改”
- 不提交疑似密钥、环境文件、临时产物

### 4. 严禁事项

- 不用 `git reset --hard`
- 不用强制覆盖类命令
- 不擅自 amend
- 不擅自 push

## 适用信号

- 用户要求提交代码
- 仓库本身已有脏改动
- 当前任务只应影响少量文件
- 需要判断哪些改动属于本次任务
