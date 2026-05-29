# Accessibility Checklist

## 目标

可访问性必须进入组件契约，不是最后“顺手检查”。默认目标是 WCAG 2.2 AA 中与前端实现直接相关的基础要求。

## 快速检查

- 所有交互元素可通过键盘访问。
- Tab 顺序符合视觉和阅读顺序。
- focus indicator 清晰可见，且不被 sticky/fixed 元素遮挡。
- 按钮、图标按钮、链接有可理解名称。
- 图标按钮必须有 `aria-label` 或等价文本。
- 点击/触摸目标至少 24x24 CSS px，或有足够间距。
- 错误、加载、成功状态不只靠颜色表达。
- 表单字段有关联 label、错误文本和帮助文本。
- 弹窗打开后焦点进入弹窗，关闭后焦点返回触发元素。
- 动画不阻止用户完成任务，必要时尊重 reduced motion。

## 组件级检查

| 组件 | 必查项 |
|---|---|
| Button | 名称、disabled 语义、focus、target size |
| IconButton | aria-label、target size、tooltip 不作为唯一名称 |
| Input | label、error、aria-describedby、键盘提交 |
| Modal/Dialog | role、focus trap、Esc、return focus |
| Tabs | arrow keys、selected state、panel 关联 |
| Menu | arrow keys、Esc、focus 管理 |
| Toast | 不抢焦点，重要信息可被读屏感知 |
| Feed/List item | 逻辑阅读顺序、来源信息、时间、错误状态 |

## 动态列表和流式内容可访问性

- 动态列表应有明确区域语义，例如描述列表用途的 `aria-label`。
- 新内容自动追加不能抢走用户正在操作的焦点。
- streaming 内容需要避免过度打断读屏；必要时降低 live region 频率。
- 复制、重试、删除等图标按钮必须有可读名称。
- 错误项要有恢复动作，例如重试。
- 视觉排列不能破坏 DOM 阅读顺序。

## 禁止模式

- 使用 `outline: none` 后没有替代 focus 样式。
- 点击区域只有 SVG 本身大小。
- 用颜色作为错误或成功的唯一提示。
- 弹窗关闭后焦点丢到页面顶部。
- 交互元素用 `div`/`span` 伪装且无键盘行为。

## 最小手动验证

1. 只用键盘 Tab/Shift+Tab/Enter/Space/Esc 完成主流程。
2. 检查每个 focus 是否可见。
3. 检查图标按钮读起来是否明确。
4. 用 DevTools 抽查点击目标尺寸。
5. 打开窄屏和 200% zoom，确认内容不丢失。
