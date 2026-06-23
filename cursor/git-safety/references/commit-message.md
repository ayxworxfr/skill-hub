# Commit Message 规范

配合 git-safety/SKILL.md §7 使用。建立可机读的 commit 历史，支持 semantic-release / 自动 changelog。

## Conventional Commits 格式

```
<type>(<scope>): <description>

[optional body]

[optional footer(s)]
```

**type 枚举**（与 building skill commit 前缀对应）：

| type | 含义 | building 对应 |
|---|---|---|
| `feat` | 新功能 | `feat:` |
| `fix` | Bug 修复 | `fix:` |
| `tidy` | 结构整理，不改行为 | `tidy:` |
| `config` | 配置 / env / feature flag 改动 | `config:` |
| `test` | 新增或修改测试 | `test:` |
| `refactor` | 大重构，非 tidy | `refactor:` |
| `docs` | 文档改动 | — |
| `chore` | 构建 / CI / 依赖（不涉及代码逻辑） | — |
| `build` | 构建系统 / 打包配置 | — |

**Breaking change**：在 type 后加 `!` 或在 footer 写 `BREAKING CHANGE: <description>`。

```
feat(api)!: change response format for /users endpoint

BREAKING CHANGE: response body now uses camelCase keys
```

## 好的 commit message 原则

- **说为什么改**，不只说改了什么（"防止空指针崩溃" > "加了空指针判断"）
- description 用**祈使句**，≤72 字符
- body 解释背景 / 动机 / 取舍，不复述 diff
- scope 可选，写受影响的模块名（如 `auth`, `api`, `db`）

## 好坏对比

```
# 坏
fix: bug fix
feat: add stuff
wip
update

# 好
fix(auth): 防止 refresh token 过期后产生竞态条件
feat(payment): 支持微信支付渠道（仅国内站）
tidy(db): 拆分 user_service.go 中混合的 CRUD 和业务逻辑
config: 将超时阈值从 5s 调整为 10s（压测后的实测建议）
```

## AI 提交时的检查门

提交前确认：

- [ ] type 在枚举范围内（不用 update / change / modify / refactor 替代 feat/fix）
- [ ] description 用祈使句，不用"added" / "changed" 过去式
- [ ] 跨多个 type 的改动 → 拆成多次 commit，不混 type
- [ ] Breaking change 已在 footer 或 `!` 标注

禁止输出：

| 禁止 | 替代 |
|---|---|
| `update: xxx` / `change: xxx` | 选具体 type（feat / fix / tidy...） |
| `feat: add xxx and fix yyy and tidy zzz` | 拆成 3 次 commit |
| `fix: fixed the bug` | `fix(模块): <具体说明>` |
| message 只有一行且无任何上下文 | 必要时加 body 说明动机 |

## 和 semantic-release 对接

semantic-release 根据 commit type 自动推 semver：

- `fix:` → patch 版本（1.0.0 → 1.0.1）
- `feat:` → minor 版本（1.0.0 → 1.1.0）
- `feat!:` / `BREAKING CHANGE:` → major 版本（1.0.0 → 2.0.0）
- `tidy:` / `docs:` / `test:` / `chore:` → 不触发发版
