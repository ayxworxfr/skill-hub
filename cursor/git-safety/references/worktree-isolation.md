# Worktree 隔离规则

配合 git-safety/SKILL.md §2 使用。多 agent / 多 session 并行编码时防止 diff 污染和 lockfile 冲突。

## 判断是否需要 worktree

满足**任一**条件时，建议建 worktree 隔离：

| 条件 | 原因 |
|---|---|
| 主工作区有用户未提交改动 | 防止 AI 改动污染用户改动 |
| 任务跨多个文件或耗时较长 | 中途切换不乱 |
| 多个 agent / session 并行 | 每人独立 branch |
| 任务运行格式化 / 代码生成 / 迁移 / 依赖安装 | 这类操作会产生大量副产物 |
| 改动风险高，失败后需要整体丢弃 | 直接删 worktree，不动主工作区 |

## 建立和使用 worktree

```bash
# 从当前分支建新 worktree
git worktree add ../task-<name> -b task/<name>

# 查看所有 worktree
git worktree list

# 完成后删除
git worktree remove ../task-<name>
# 如果目录已被意外删除，清理元数据
git worktree prune
```

worktree 放置原则：
- 放在 repo 目录**外**（如 `../`），或放在已被 `.gitignore` 的目录
- 不要嵌套放在 repo 内的未被 ignore 目录

## 并发冲突门（多 agent 场景）

以下文件**禁止**多个 worktree / agent 并行修改：

| 文件类型 | 原因 | 处理方式 |
|---|---|---|
| `package-lock.json` / `yarn.lock` / `go.sum` | lockfile 变更必须串行 | 指定一个 agent 负责，其他等待 |
| 核心配置文件（`vite.config.ts` / `webpack.config.js`） | 构建产物依赖，合并复杂 | 串行或提前协商边界 |
| 数据库迁移文件 | 迁移顺序不能乱 | 严格串行 |
| 公共类型定义 / 接口文件 | 改了会破坏其他 agent 的依赖 | 先锁定接口再并行实现 |
| 入口文件（`main.ts` / `app.py` / `index.ts`） | 每个 agent 都可能改注册/路由 | 串行 |

发现重叠文件时 → 序列化任务，不靠最后 merge 碰运气。

## Merge 前检查

合并 worktree 的 branch 到主分支前：

```bash
# 确认目标分支无新提交（避免 diverge）
git fetch origin
git log HEAD..origin/<target-branch> --oneline

# 如果目标分支有更新，先 rebase
git rebase origin/<target-branch>

# 确认没有重叠文件的冲突
git diff <target-branch>...HEAD --name-only | sort > /tmp/my_files.txt
# 对比其他 agent 的 branch
git diff <target-branch>...<other-agent-branch> --name-only | sort > /tmp/other_files.txt
comm -12 /tmp/my_files.txt /tmp/other_files.txt  # 交集 = 冲突风险
```

## 清理规则

- 任务完成且已合并 → `git worktree remove <path>`
- 任务放弃 → `git worktree remove <path>` + `git branch -d task/<name>`
- 禁止用 `rm -rf` 直接删 worktree 目录（会留下 `.git/worktrees/` 元数据）
- 意外删除后 → `git worktree prune`
