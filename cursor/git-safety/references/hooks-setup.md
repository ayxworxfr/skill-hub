# Git Hook 配置详解

提交前自动化质量门：格式化 staged 文件 + secret 扫描 + commit message 校验。配合 git-safety/SKILL.md §7 使用。

## Hook 管理器选型

| 管理器 | 适用场景 | 优势 | 劣势 |
|---|---|---|---|
| **pre-commit** | 跨语言 / 多技术栈 | 社区 hook 丰富，python 无需额外安装 | 串行，大仓慢；需 python |
| **lefthook** | 追求速度 / 单二进制部署 | 并行执行，~10x；Go 二进制 | 社区 hook 少，需单独安装 |
| **husky + lint-staged** | 纯 JS/TS 项目 | npm 生态无缝，lint-staged 只处理 staged 文件 | 只适合 JS 项目；两工具组合 |

**跨语言项目推荐 pre-commit**；JS 项目推荐 husky + lint-staged；追求性能推荐 lefthook。

模板见 [../assets/lefthook.yml](../assets/lefthook.yml) 和 [../assets/.pre-commit-config.yaml](../assets/.pre-commit-config.yaml)。

## lint-staged 模式（关键）

只处理 staged 文件，不动用户其他改动——AI 编码场景必须遵守此原则。

```bash
# 正确：只处理 staged 文件
git diff --name-only --cached | xargs prettier --write
# 错误：会动整个 repo
prettier --write .
```

scripts/format_staged.py 实现了跨语言的 lint-staged 等价逻辑，作为无外部依赖的备用方案。

## 格式化 Hook 配置（pre-commit 示例）

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v5.0.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-added-large-files
        args: ['--maxkb=500']

  # Python
  - repo: https://github.com/astral-sh/ruff-pre-commit
    rev: v0.9.0
    hooks:
      - id: ruff-format

  # JS/TS
  - repo: https://github.com/pre-commit/mirrors-prettier
    rev: v3.1.0
    hooks:
      - id: prettier
        types_or: [javascript, typescript, css, json, yaml, markdown]

  # Go
  - repo: https://github.com/dnephin/pre-commit-golang
    rev: v0.5.1
    hooks:
      - id: go-fmt
```

## commit-msg Hook（Conventional Commits）

```bash
# .git/hooks/commit-msg（或通过 lefthook 配置）
#!/bin/sh
msg=$(cat "$1")
pattern="^(feat|fix|docs|style|refactor|test|tidy|config|chore|build|ci)(\(.+\))?: .+"
if ! echo "$msg" | grep -qE "$pattern"; then
  echo "错误：commit message 不符合 Conventional Commits 格式"
  echo "格式：<type>(<scope>): <description>"
  echo "有效 type：feat / fix / docs / tidy / config / refactor / test / chore"
  exit 1
fi
```

配合 commitlint（JS 项目）：

```bash
npm install --save-dev @commitlint/cli @commitlint/config-conventional
echo "module.exports = {extends: ['@commitlint/config-conventional']}" > commitlint.config.js
# husky 里：
echo "npx --no -- commitlint --edit \$1" > .husky/commit-msg
```

## pre-push Hook（推送前跑测试）

```bash
# .git/hooks/pre-push（或通过管理器配置）
#!/bin/sh
# 只在非 main/master 分支跑快速测试
branch=$(git rev-parse --abbrev-ref HEAD)
if [ "$branch" != "main" ] && [ "$branch" != "master" ]; then
  # 按项目替换以下命令
  npm test --if-present || python -m pytest -x -q 2>/dev/null || echo "no test runner found"
fi
```

## 安装和卸载

```bash
# pre-commit
pip install pre-commit
pre-commit install            # 安装 pre-commit hook
pre-commit install --hook-type commit-msg  # 安装 commit-msg hook
pre-commit run --all-files    # 手动跑全部

# lefthook
brew install lefthook         # macOS
winget install Arkweid.lefthook  # Windows
lefthook install

# 临时跳过（用户明确批准时才用）
SKIP=prettier git commit ...
PRE_COMMIT_ALLOW_NO_CONFIG=1 git commit ...
```

## 配置后验证

安装后必须跑一次：

```bash
pre-commit run --all-files   # 或 lefthook run pre-commit
# 确认：格式化 hook 运行 + 无误格式化用户未改动的文件
```

禁止声称"配置好了"但没跑过验证。
