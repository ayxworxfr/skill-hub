---
name: verifying
description: Verifies a change with concrete evidence (commands, results, coverage paths) before claiming completion. Use when finishing implementation/bugfix/refactor/frontend change/config change/pre-commit work, or when the user asks "did it work" / "verify this" / "is it really fixed" / "ready to merge". Other skills (building, debugging, refactoring, designing-frontend, git-safety) reference this skill at their verification step.
---

# Verifying

## Core Principle

把"我觉得完成了"改成"证据证明完成了"。验证是交付门，不是可选附加项。**没跑命令就不许声称已验证；跑了无关命令冒充验证等同于没跑。**

## 适用范围

用于任何声称完成前的验收：

- 功能实现、bug 修复、重构、配置改动、前端 UI 改动
- 提交前检查
- 用户要求确认是否已修好、是否可合并、是否无影响

不要用于：

- 纯解释、纯方案、只读分析（除非用户要求验证结论）
- 还在 plan 阶段（用 `planning`）

## 强制流程

### 1. 找验证入口

读项目提供的入口，不要编造命令：

- `package.json` scripts
- `pyproject.toml` / `setup.cfg` / `tox.ini`
- `Makefile` / `justfile` / `taskfile.yml`
- README / CONTRIBUTING / 开发文档
- CI 配置（`.github/workflows/`、`.gitlab-ci.yml` 等）
- 现有测试目录

### 2. 选最小有效验证

| 改动类型 | 优先验证 |
|---|---|
| 业务逻辑（任意语言） | 相关单元/集成测试、脚本运行、import/编译检查 |
| 类型/编译 | typecheck、build |
| UI/布局 | 浏览器手动检查、截图、Storybook、Playwright、响应式三档 |
| 配置/路径/env | 正常配置 + 缺省配置各至少一条路径 |
| 数据处理 | 输入输出对比、字段/行数/类型检查 |
| API/接口 | 请求响应、错误路径、契约字段 |
| 重构 | 改动前后同一行为对照 |
| Git 提交前 | status、diff、测试结果、敏感文件检查 |

最小 ≠ 不充分。覆盖本次改动的所有主分支才算最小。影响范围大时升级到更广验证。

### 3. 中段自检

跑命令前确认：

- [ ] 所选命令能直接覆盖本次改动的关键路径
- [ ] 命令存在于项目脚本/配置里，不是凭通用经验编造
- [ ] 不只跑无关命令凑数

### 4. 记录证据

输出必须包含：

- 命令或检查方式（具体到可复制粘贴）
- 结果（通过/失败的关键摘要）
- 失败时的错误片段
- 没验证的部分和原因

### 5. 失败处理

- 先读错误，不机械重跑
- 判断失败是否由本次改动引入
- 能修则修完再跑
- 不能修则说明阻塞、影响范围、下一步证据

### 6. Final Gate

输出前确认：

- [ ] 命令、结果、覆盖路径、未验证、风险五字段齐全
- [ ] 没有触发"禁止输出模式"任一行
- [ ] 失败被忽略的情况已显式说明
- [ ] UI 改动不只跑了 lint 就声称布局正确

任一未通过不得声称完成。

## 检查门

以下情况不得声称完成：

- 跑了无关命令冒充验证
- 命令失败但忽略
- 没跑验证却写"已验证"
- UI 改动只跑 lint 就说布局正确
- 无法验证但没说明原因
- 验证只覆盖 happy path，但改动包含失败路径

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "测试一下就行" | 给出具体命令和预期结果 |
| "应该通过" | 运行命令或写明未验证原因 |
| "没有影响" | 列出检查过的路径和证据 |
| "构建失败和我无关" | 说明失败位置、是否与本次改动相关 |
| "浏览器里看一下" | 写明页面、操作步骤、视口、预期表现 |
| "本地通过即可" | 说明 CI 是否需要、关键回归路径是否覆盖 |

## 输出格式

```markdown
验证：
- 已运行：<命令>
- 结果：<通过/失败摘要>
- 覆盖路径：<本次改动的哪些分支>
- 未验证：<明确列出，写"无"也可>
- 风险：<剩余风险，写"无"也可>
```
