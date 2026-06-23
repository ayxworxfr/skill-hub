# Secret 扫描与大文件检测

配合 git-safety/SKILL.md §敏感文件规则使用。靠 AI 自觉发现密钥不够——用工具在提交前自动拦。

## Secret 扫描工具选型

| 工具 | 安装 | 扫描方式 | 适合场景 |
|---|---|---|---|
| **gitleaks** | 单二进制（Go） | staged diff / git history | 推荐：快、离线、易集成 |
| **trufflehog** | pip / Docker | 深度 entropy 分析 | 老历史扫描；较慢 |
| **detect-secrets** | pip | 可配置白名单 | Python 项目 |

## gitleaks 快速上手

```bash
# 安装
brew install gitleaks          # macOS
winget install zricethezav.gitleaks  # Windows
pip install gitleaks           # 通用

# 只扫 staged 文件（pre-commit 场景）
gitleaks protect --staged

# 扫整个 repo 历史
gitleaks detect

# 扫本次 diff
gitleaks protect
```

配置文件见 [../assets/gitleaks.toml](../assets/gitleaks.toml)，放到仓库根目录。

## pre-commit 集成

在 `.pre-commit-config.yaml` 加：

```yaml
- repo: https://github.com/gitleaks/gitleaks
  rev: v8.21.2
  hooks:
    - id: gitleaks
      name: detect secrets
      args: ['--staged']
```

## 常见 secret 模式（AI 需主动识别）

| 类型 | 特征 | 应对 |
|---|---|---|
| API key | `sk-...` / `key-...` / `AKIA...` / 长随机串 | 换成环境变量 |
| JWT / token | `eyJ...` base64 开头 | 不提交，用 `.env` |
| 私钥 | `-----BEGIN RSA PRIVATE KEY-----` | 绝不提交，加 .gitignore |
| DB 连接串 | `postgres://user:pass@host` | 用 secret manager |
| 内网 IP / 路径 | `192.168.x.x` / `C:\Users\...` | 看是否为调试遗留 |

## 大文件检测

提交大文件会永久膨胀 git history，无法轻易撤销。

```bash
# 手动检查（暂存前）
git diff --cached --stat | grep -E "[0-9]{4,} insertion"

# pre-commit 自动拦（maxkb 按项目调整）
- repo: https://github.com/pre-commit/pre-commit-hooks
  rev: v5.0.0
  hooks:
    - id: check-added-large-files
      args: ['--maxkb=500']
```

**应直接拒绝提交**的文件类型：

- 二进制构建产物（`.dll` / `.exe` / `.wasm`）
- 压缩包（`.zip` / `.tar.gz`）> 100KB
- 媒体文件（`.mp4` / `.mov` / `.psd`）
- 数据库 dump（`.sql` / `.db`）

改用 Git LFS 或外部存储（S3 / CDN）。

## 误报白名单

gitleaks.toml 里加 `[[allowlists]]` 配置：

```toml
[[allowlists]]
description = "test fixtures and example configs"
paths = [
  "tests/fixtures/.*",
  "docs/examples/.*",
]
regexes = [
  "example_token_here",
]
```

## 检查门

以下情况不得声称扫描通过：

- 只靠 AI 目视检查，没有工具验证
- gitleaks 报 finding 但用 `--no-verify` 绕过
- 白名单配置覆盖了真实密钥路径
- 扫过历史后发现泄露但未 rotate 密钥
