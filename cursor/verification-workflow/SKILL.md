---
name: verification-workflow
description: Use when finishing implementation, bugfix, refactor, frontend change, config change, or pre-commit work that needs evidence from tests, lint, typecheck, build, runtime checks, screenshots, logs, or manual validation.
---

# Verification Workflow

## 目标

把“我觉得完成了”改成“证据证明完成了”。验证是交付门，不是可选附加项。

## 适用范围

用于任何声称完成前的验收：

- 功能实现、bug 修复、重构、配置改动、前端 UI 改动
- 提交前检查
- 用户要求确认是否已修好、是否可合并、是否无影响

不要用于纯解释、纯方案、只读分析，除非用户要求验证结论。

## 验证选择矩阵

| 改动类型 | 优先验证 |
|---|---|
| Python 逻辑 | 相关 pytest、脚本运行、导入检查 |
| TypeScript/前端逻辑 | typecheck、lint、相关测试 |
| UI/布局 | 浏览器检查、截图、Storybook、Playwright、响应式检查 |
| 配置/路径/env | 正常配置和缺省配置各至少一条路径 |
| 数据处理 | 输入输出文件对比、字段/行数/类型检查 |
| API/接口 | 请求响应、错误路径、契约字段 |
| 重构 | 改动前后同一行为验证 |
| Git 提交前 | status、diff、测试结果、敏感文件检查 |

## 强制流程

### 1. 找到验证入口

先读项目提供的验证入口：

- `package.json` scripts
- `pyproject.toml`
- `Makefile`
- README/开发文档
- CI 配置
- 现有测试目录

不要编造不存在的命令。

### 2. 选择最小有效验证

验证必须直接覆盖本次改动。优先跑最小相关命令；影响范围大时再跑更广验证。

例：

- 改单个 Python 函数：相关 pytest 用例优先。
- 改公共类型或构建配置：typecheck/build 优先。
- 改 UI 布局：浏览器或组件预览检查优先，lint 只能证明语法，不证明布局。

### 3. 记录证据

输出必须包含：

- 命令或检查方式
- 结果
- 失败时的错误摘要
- 没验证的部分和原因

### 4. 失败处理

验证失败时：

- 先读错误，不机械重跑
- 判断失败是否由本次改动引入
- 能修则修完再跑
- 不能修则说明阻塞、影响范围和下一步证据

## 检查门

以下情况不能声称完成：

- 只跑了无关命令
- 命令失败但忽略
- 没跑验证却写“已验证”
- UI 改动只跑 lint 就说布局正确
- 无法验证但没说明原因

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| “测试一下就行” | 给出具体命令和预期结果 |
| “应该通过” | 运行命令或写明未验证原因 |
| “没有影响” | 列出检查过的路径和证据 |
| “构建失败和我无关” | 说明失败位置、是否与本次改动相关 |
| “浏览器里看一下” | 写明页面、操作步骤、视口、预期表现 |

## 输出格式

```markdown
验证：
- 已运行：
- 结果：
- 覆盖路径：
- 未验证：
- 风险：
```

没有风险时，`风险` 写“无”。
