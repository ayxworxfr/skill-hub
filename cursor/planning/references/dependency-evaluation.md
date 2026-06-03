# Evaluation Checklist

deps 子模式的评估维度详解 + 各语言查证命令 + 供应链工具。流程入口和输出模板见 SKILL.md 同级链接的 `dependency-selection.md`。

## 核心原则

Stars 是弱信号，不是质量结论。依赖选型要综合维护活跃度、安全姿态、社区采用、许可证、文档质量和项目适配成本。

## 评估维度

### 1. 功能匹配

- 是否解决当前核心需求，而不是只解决相邻问题？
- API 是否覆盖关键边界场景？
- 是否过度复杂或过度宽泛？
- 是否支持当前语言、框架、运行时和部署环境？

### 2. 维护活跃度

检查：

- 最近 commit 时间
- 最近 release/publish 时间
- release 频率是否稳定
- issue 是否有人回应
- PR 是否有人 review/merge
- changelog 是否清晰

风险信号：

- 12 个月以上无 release 且 issue 堆积
- 18 个月以上无明显维护活动
- archived、deprecated、停止维护公告
- breaking changes 无迁移文档

查证命令见末尾"各语言查证命令"。

### 3. 社区和采用

检查：

- stars/forks/watchers
- npm/PyPI/Maven/Cargo 下载量和趋势
- dependent packages 或被知名项目使用情况
- discussions、Discord、论坛、Stack Overflow 活跃度
- issue 质量和社区回应

注意：

- stars 代表曝光和历史热度，不等于当前健康。
- 下载量要看趋势，不只看绝对数。
- 小众但维护稳定的库可以优于大而废弃的库。

### 4. 维护者和治理

检查：

- 活跃贡献者数量
- 是否单维护者
- 是否有组织、基金会或公司支持
- 是否有贡献指南、CODEOWNERS、治理说明
- 是否有 bus factor 风险

风险信号：

- 单维护者 + 无 release + 大量未处理 issue
- maintainer 突然更换且无说明
- 发布者和 GitHub 仓库身份不一致

### 5. 安全和供应链

检查：

- 已知 CVE 和 advisories
- `npm audit`、`pip audit`、Snyk、OSV、deps.dev 等结果
- 是否有 `SECURITY.md`
- OpenSSF Scorecard 或同类安全评分
- 是否使用危险 install/postinstall scripts
- 依赖树是否过深，是否引入高风险 transitive dependencies
- 是否有 signed releases、provenance、checksums 或 lockfile 支持

风险信号：

- high/critical 漏洞未修
- 无安全报告渠道
- 包名和官方项目不一致，疑似 typosquatting
- 新包发布时间很短但要求高权限或安装脚本复杂

查证命令见末尾"各语言查证命令"和"OpenSSF / 供应链工具"。

### 6. 许可证

检查：

- 是否有 LICENSE 文件
- 是否是 OSI 常见许可证
- MIT/Apache/BSD 通常风险较低
- GPL/AGPL/LGPL/MPL 等需结合项目分发方式评估
- 商业限制、云服务限制、双许可证条款

阻断：

- 无 LICENSE 时，不推荐直接引入。
- GPL/AGPL 类许可证必须提示用户确认。

### 7. 工程质量

检查：

- 文档和最小示例是否清楚
- 测试是否存在，CI 是否通过
- TypeScript 类型或类型存根是否维护
- API 是否稳定，semver 是否可信
- bundle size、tree-shaking、side effects
- SSR、浏览器、Node、Python 版本、平台兼容性

辅助工具：

- JS bundle 体积：Bundlephobia、pkg-size
- TS 类型：内置类型 / DefinitelyTyped / `exports` / `types` 字段
- Python 类型：`py.typed`、type stubs、mypy / pyright 支持

### 8. 项目适配

检查：

- 是否和当前项目已有依赖重复
- 是否符合当前框架和目录结构
- 是否需要 adapter 封装
- 是否影响包体、构建时间、运行性能
- 是否有迁移和退出路径

## 各语言查证命令

### JavaScript / TypeScript

```bash
npm view <package> version time license dependencies peerDependencies repository
npm view <package> maintainers dist-tags
npm audit
```

辅助页：npm package 页（版本/发布时间/weekly downloads/maintainers）、GitHub repo（stars/issues/PR/release/CI/license）、npm trends（下载趋势）。

### Python

```bash
python -m pip index versions <package>
pip audit
```

辅助页：PyPI（版本/发布时间/Python version/license/project links）、GitHub repo（维护/issue/CI/测试）。

### Java / JVM

- Maven Central 页：版本、发布时间、groupId/artifactId、签名
- GitHub / GitLab：维护和文档
- 安全：OWASP Dependency-Check、Snyk、OSV、deps.dev
- 许可证：pom metadata、LICENSE

### Rust

```bash
cargo audit
cargo tree
```

辅助页：crates.io（版本/downloads/owners/dependencies）、docs.rs（文档生成是否成功）、GitHub（维护和 issue）、RustSec advisory database。

### Go

```bash
go list -m -versions <module>
govulncheck ./...
```

辅助页：pkg.go.dev（文档/import path/版本）、GitHub（维护/release/issues）、OSV。

## OpenSSF / 供应链工具

跨语言通用：

- OpenSSF Scorecard：维护、安全策略、许可证、依赖更新、CI、分支保护等评分
- deps.dev：依赖、漏洞、项目健康信息
- OSV.dev：开源漏洞数据库
- Snyk / Socket.dev / Aikido：安全和供应链风险
- SBOM：CycloneDX、SPDX，用于记录依赖树

## 使用原则

- 工具结果是证据，不是唯一结论。
- 包管理器数据和源码仓库都要看，防止包名仿冒或 fork 混淆。
- 有高风险安全或许可证问题时，总分再高也不能直接推荐。
- 无法运行本地命令时，说明未验证项，不要伪造结果。

## 建议评分

| 维度 | 权重 |
|---|---|
| 功能匹配 | 20 |
| 维护活跃度 | 20 |
| 安全和供应链 | 20 |
| 项目适配 | 15 |
| 社区和采用 | 10 |
| 工程质量 | 10 |
| 许可证 | 5 |

评分只用于辅助决策，不得用单一总分掩盖关键阻断风险（无 LICENSE、未修 critical CVE、archived 等）。
