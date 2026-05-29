# Skills 总览

这套个人 Skills 按“工作模式”拆分。每个 Skill 必须有清晰触发条件、动作化流程、检查门、反逃逸规则和验证证据要求。

## 总原则

- **先路由再执行**：先判断任务类型，再加载对应 Skill，不把所有规则混成一坨。
- **先证据后结论**：读代码、查配置、跑命令、看 diff 之后再判断。
- **先契约后实现**：需求、布局、接口、行为、验证标准不清楚时，不进入编码。
- **完成必须可验证**：没有测试、构建、lint、运行时证据或明确未验证原因，不声称完成。
- **禁止半成品交付**：不写占位、临时兼容、只覆盖 happy path、默认值掩盖问题。
- **保护用户改动**：脏工作区内只处理当前任务相关变更，不回滚不相关改动。

## 路由顺序

1. `code-understanding-workflow`：先读代码、梳理模块、调用链、数据流、影响范围。
2. `large-feature-delivery-workflow`：跨模块、多阶段、长期推进的大需求。
3. `solution-design-workflow`：用户要方案、架构取舍、技术选型、先不写代码。
4. `frontend-product-design-workflow`：前端 UI、布局、组件、响应式、设计系统、前端架构。
5. `bugfix-and-debug-workflow`：报错、异常结果、回归、环境差异、偶发失败。
6. `safe-refactor-workflow`：重构、整理结构、抽公共逻辑，要求行为不变。
7. `code-review-workflow`：review diff、PR、提交、风险评估。
8. `general-development-workflow`：普通功能实现、业务逻辑补充、脚本和模块开发。
9. `pytest-workflow`：pytest 测试设计、回归测试、修测试。
10. `config-aware-workflow`：YAML/JSON/env/路径/feature flag/运行配置驱动的行为。
11. `git-safety-workflow`：提交、暂存、整理本地改动、脏工作区保护。
12. `verification-workflow`：完成前验收、测试/构建/lint/运行时证据收集。

## 常见组合

- 前端页面或组件：`frontend-product-design-workflow` + `general-development-workflow` + `verification-workflow`
- 前端方案或技术选型：`solution-design-workflow` + `frontend-product-design-workflow`
- 新功能开发：`general-development-workflow` + `verification-workflow`
- 修 bug：`bugfix-and-debug-workflow` + `pytest-workflow` + `verification-workflow`
- 重构：`safe-refactor-workflow` + `verification-workflow`
- 配置驱动改动：`config-aware-workflow` + `general-development-workflow` + `verification-workflow`
- 大型需求：`large-feature-delivery-workflow` + `solution-design-workflow` + 对应专项 Skill
- 提交前整理：`git-safety-workflow` + `verification-workflow`

## Skill 质量标准

每个 `SKILL.md` 必须满足：

- frontmatter 的 `description` 只写触发条件，不总结流程。
- 正文包含适用范围、非适用范围、强制流程、检查门、禁止输出模式、最终检查。
- 复杂知识放到一层 `references/`，主文件保持可扫描。
- 规则必须动作化：不用“注意性能”，改成“检查哪些路径，用什么命令，失败怎么处理”。
- 输出要求必须可验证：具体命令、具体路径、具体对比方式。

## 新增 Skill 判断

只有同时满足以下条件才新建：

- 任务模式稳定且不同于现有 Skill。
- 触发词稳定，不会大量抢占现有 Skill。
- 输出结构稳定。
- 需要独立 reference 或检查门。

否则优先改现有 Skill。
