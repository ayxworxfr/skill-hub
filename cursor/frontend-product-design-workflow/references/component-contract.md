# Component Contract

## 目标

组件契约用于在写代码前消除歧义：组件由哪些部分组成、允许什么变化、哪些状态必须覆盖、内容异常时如何保持布局稳定。

## 组件契约模板

```text
组件名：
用途：
非用途：

Anatomy：
- root：
- container：
- leading slot：
- content slot：
- trailing slot：
- actions：
- feedback：

Props / Variants：
- variant：
- size：
- density：
- disabled：
- loading：
- selected：
- error：

State Matrix：
- default：
- hover：
- focus：
- active：
- disabled：
- loading：
- empty：
- error：
- selected：

Layout Rules：
- 宽度：
- 高度：
- 对齐：
- gap/padding：
- 换行：
- 溢出：

Content Rules：
- 长文本：
- 多语言：
- 图标缺失：
- 图片/代码/表格：

Interaction Rules：
- 鼠标：
- 键盘：
- 触摸：
- 焦点：

Accessibility：
- 语义元素：
- aria：
- focus：
- target size：

Acceptance Criteria：
- 可验证标准 1：
- 可验证标准 2：
```

## Anatomy 规则

Anatomy 必须描述组件结构，不描述颜色好不好看。

常用组成：

- `root`：组件边界，负责布局上下文。
- `container`：视觉容器，负责背景、边框、圆角、阴影。
- `leading`：左侧图标、头像、状态点。
- `content`：主文本、正文、输入区域。
- `trailing`：右侧图标、快捷操作、状态。
- `actions`：按钮、菜单、复制、删除、重试。
- `feedback`：错误、帮助文本、加载进度。

## State Matrix

交互组件至少检查：

| 状态 | 必须定义 |
|---|---|
| default | 默认视觉和行为 |
| hover | 鼠标反馈，触屏不能依赖它 |
| focus | 键盘焦点可见 |
| active | 按下反馈 |
| disabled | 不可交互，样式和语义都禁用 |
| loading | 是否阻止重复提交 |
| error | 错误文案、颜色、aria 关系 |
| empty | 无数据时的内容和行动入口 |

## Slots 规则

Slot 是允许变化的内容区域，不是随便塞内容的洞。

- 每个 slot 必须有职责。
- 每个 slot 必须有尺寸和溢出规则。
- slot 内容变化不能破坏 root 布局。
- 如果 slot 允许图标、头像、按钮、文本混用，必须定义优先级和间距。
- 不常复用的业务组件不要为了“灵活”开放过多 slot。

## 组件拆分判断

拆组件前先问：

- 这个部分是否有独立职责？
- 它是否有独立状态或交互？
- 它是否会被复用？
- 拆出来后调用方是否更清楚？

满足 2 条以上才拆。只为减少单文件行数而拆，通常不是好拆分。

## 阻断条件

- 复杂组件没有 anatomy，不允许实现。
- 组件有交互但没有 state matrix，不允许交付。
- 有动态内容但没有 overflow/content rules，不允许交付。
- 有 icon button 但没有 accessible label，不允许交付。
