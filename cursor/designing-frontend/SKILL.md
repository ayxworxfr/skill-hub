---
name: designing-frontend
description: Designs and implements frontend UI by enforcing layout contract before visual decoration. Walks through task type, project context, structure diagram, layout contract, component contract, visual decisions, and verification. Use when the user builds/modifies React/Vue/Next/Vite pages or components, plans layouts, designs dashboards, fixes broken layouts, designs frontend architecture, or makes UI technical choices.
---

# Designing Frontend

## Core Principle

把前端工作从"直接写组件和调样式"改成稳定流程：先理解产品任务，再建模布局，再定义组件契约，最后实现和验证。

**布局契约优先于视觉装饰。** 复杂 UI 没有布局区域图、槽位职责和溢出规则时，不允许开始写代码。

## 适用范围

优先用于：

- 构建或修改 React、Vue、Next、Vite 页面与组件
- 设计 UI、布局、交互、响应式页面或复杂界面结构
- 做前端技术选型、状态管理、组件架构、目录结构设计
- 重构前端模块、整理组件边界、修复布局错位
- 优化可访问性、性能、设计系统一致性

不要用于：

- 纯后端、纯 Python、纯数据库任务
- 只问一个 CSS/TypeScript 语法点
- 纯 diff review：用 `reviewing-code`
- 用户明确只要方案：先用 `planning`，再用本 Skill 做前端约束

## 强制流程

### 1. 识别前端任务类型

判断当前任务属于哪类，不清楚就先说明判断依据：

- UI 视觉设计
- 布局修复
- 组件或页面实现
- 前端架构设计
- 技术选型
- 前端重构
- 性能、响应式或可访问性优化

### 2. 读取项目上下文

改现有项目时，先检查：

- 框架和构建工具：React、Vue、Next、Vite 等
- 样式系统：Tailwind、CSS Modules、CSS-in-JS、组件库、自研 token
- 目录结构：是否按 `features/`、业务模块、shared UI 分层
- 已有相似页面、组件、hook、状态管理、数据请求模式
- lint、typecheck、test、build 命令

禁止没看项目结构就凭通用经验新增一套前端风格。

涉及框架、组件库、状态管理、样式方案或新依赖时，先按 `references/tech-selection.md` 做技术选型检查。

### 3. 建立界面结构图

写代码前必须用文本线框图描述页面或组件结构：

```text
PageOrComponent
├─ RegionA
├─ RegionB
│  ├─ Slot1
│  └─ Slot2
└─ RegionC
```

结构图必须回答：

- 页面有哪些区域
- 每个区域负责什么
- 哪些区域固定，哪些区域伸缩
- 内容过长、为空、加载中、失败时放在哪里

布局修复必须先画当前错误布局和目标布局。

### 4. 声明布局契约

实现前必须写出布局契约：

- 容器使用 Grid、Flex、普通流还是定位，为什么
- 每个槽位的宽度、高度、对齐、伸缩、换行、溢出规则
- 哪些元素允许进入哪些槽位，哪些元素禁止进入
- 小屏幕如何变化，变化后哪些边界仍然成立
- 长文本、代码块、图片、表格、按钮组如何不撑破布局

布局阻断条件：

- 没有布局契约，不许写代码
- 主布局依赖 `absolute`、负 margin、魔法 padding 时，必须重做布局模型
- 视觉上"看起来对"但槽位职责不清时，不能交付

详细规则见 `references/layout-modeling.md`。响应式细则见 `references/responsive-design.md`。

### 5. 定义组件契约

复杂组件必须先定义组件契约：

- **Anatomy**：root、container、slots、content、actions、feedback 等组成部分
- **Props/variants**：尺寸、密度、语义、角色、状态
- **State matrix**：default、hover、focus、active、disabled、loading、empty、error、selected
- **Content rules**：换行、截断、滚动、最大宽度、最小宽度、国际化文本
- **Interaction rules**：点击、键盘、焦点、关闭、提交、取消
- **Accessibility**：语义标签、aria、焦点顺序、可点击区域

详细模板见 `references/component-contract.md`。

### 6. 视觉设计决策

写样式前先定视觉策略：

- 产品气质：专业工具、数据密集、协作型、沉浸式、极简等
- 信息层级：主内容、辅助信息、状态提示、危险操作
- 密度：紧凑、标准、舒展
- token：颜色、间距、圆角、阴影、字体、行高
- 动效：只服务状态变化和反馈，不用动效掩盖布局问题

禁止只写"现代、简洁、美观"。必须落到层级、间距、色彩角色和状态表现。详细规则见 `references/ui-design-process.md`。

### 7. 中段自检

实现前确认：

- [ ] 结构图、布局契约、组件契约、视觉决策都已就位
- [ ] loading/empty/error/disabled/overflow 状态已纳入契约
- [ ] 已读项目现有前端模式（具体引用某个相似组件或页面）

任一未通过 → 回 Step 3-6 补，禁止前进到实现。

### 8. 按现有架构实现

实现时遵守：

- 先写 DOM/JSX 结构，再写布局，再写视觉，再写交互
- 优先使用项目已有组件、token、工具函数和数据请求模式
- 业务专属组件放在业务模块内，共享基础组件才进入 shared/ui
- 不为一次性页面过早抽象公共组件
- 不直接把第三方 UI 组件散落在业务代码里；需要复用时包一层项目 UI 语义

前端架构规则见 `references/frontend-architecture.md`。

### 9. 验证

交付前至少完成最相关的验证：

- 类型：typecheck 或 TypeScript 编译
- 静态检查：lint
- 构建：frontend build
- 交互：浏览器手动检查、截图、Playwright、Storybook 或组件预览
- 响应式：窄屏、标准屏、宽屏至少说明一个检查方式
- 可访问性：键盘 Tab、focus 可见、aria-label、目标尺寸

详细策略见 `verifying` skill；前端专项检查见 `references/validation-checklist.md` 和 `references/accessibility-checklist.md`。无法验证时必须说明原因和风险，不能写"应该没问题"。

## Final Gate

输出前逐项确认：

- [ ] 已经画出界面结构图，或说明无需结构图的原因
- [ ] 声明了布局契约：区域、槽位、伸缩、溢出、响应式
- [ ] 定义了复杂组件的 anatomy、slots、states
- [ ] 覆盖 loading、empty、error、disabled、overflow 中相关状态
- [ ] 遵守项目现有前端技术栈和目录结构
- [ ] 完成最小有效验证或明确未验证原因
- [ ] 没有触发"禁止输出模式"任一行

任一项未通过不得声称完成。

## 禁止输出模式

| 禁止输出 | 替代动作 |
|---|---|
| "布局已经调整好了" | 列出布局区域、槽位宽度、伸缩规则和验证方式 |
| "看起来更美观了" | 说明视觉层级、间距系统、色彩角色和状态表现 |
| "建议用户自行测试" | 给出具体测试命令、浏览器检查路径和预期结果 |
| "组件比较简单，不需要设计" | 至少写最小结构图和状态清单 |
| "其他部分保持不变" | 明确列出未修改范围或直接交付完整代码变更 |
| "可能是 CSS 问题" | 追溯到具体布局契约、选择器、盒模型或渲染状态 |
| "响应式没问题" | 说明窄/中/宽三档分别检查的方式和结果 |
