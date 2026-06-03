# Frontend Architecture

## 核心原则

前端目录结构应该反映产品和业务边界，而不是只反映技术类型。共享层提供通用能力，业务层拥有产品语义。

## 推荐分层

```text
src/
├─ app/                         # 应用装配：路由、provider、全局布局
├─ features/                    # 业务功能模块
│  └─ feature-name/
│     ├─ components/
│     ├─ hooks/
│     ├─ api/
│     ├─ model/
│     └─ types.ts
├─ shared/
│  ├─ ui/                       # 项目级基础 UI
│  ├─ lib/                      # 通用工具
│  ├─ hooks/                    # 跨业务 hook
│  └─ styles/                   # token、theme、global css
└─ pages/ or routes/            # 框架路由入口
```

按项目现有结构调整，不强行迁移。

## 放置规则

| 内容 | 放置位置 | 判断标准 |
|---|---|---|
| 业务页面组件 | `features/<module>/components` | 只服务一个业务模块 |
| 业务 hook | `features/<module>/hooks` | 依赖业务状态或业务 API |
| API 调用 | `features/<module>/api` | 与具体业务接口绑定 |
| 基础按钮/输入/弹窗 | `shared/ui` | 跨模块复用，语义通用 |
| 第三方组件封装 | `shared/ui` 或项目 UI 层 | 统一默认值、a11y、主题 |
| 通用工具函数 | `shared/lib` | 不依赖业务含义 |

## 组件边界

优先区分：

- Page：组织数据和页面布局。
- Feature component：表达业务语义。
- UI primitive：无业务语义的通用视觉组件。
- Hook：封装状态、请求、副作用。

不要把业务语义塞进 shared UI，也不要把基础 UI 细节散落在业务页面里。

## 状态归属

| 状态类型 | 默认归属 |
|---|---|
| 输入框临时值 | 局部组件 |
| 弹窗打开/关闭 | 最近公共父组件或局部 hook |
| 服务端数据缓存 | Query/SWR/项目现有请求层 |
| 跨页面用户设置 | 全局 store 或 app provider |
| 表单提交状态 | 表单组件或业务 hook |
| 纯展示 hover/focus | CSS 或局部状态 |

## 技术选型门

新增依赖前必须说明：

- 现有项目是否已有等价能力。
- 新依赖解决什么不可避免的问题。
- 包体、维护、类型支持、SSR、可访问性风险。
- 是否能用原生 CSS/平台能力解决。

默认不为单个页面引入大型 UI、动画或状态库。

## 重构边界

允许：

- 把大组件拆成有清晰职责的局部组件。
- 把重复布局模式提取到同一 feature 内。
- 给第三方 UI 包项目语义层。
- 删除无用组件、状态和样式。

谨慎：

- 跨 feature 抽 shared 组件。
- 改公共组件 API。
- 迁移目录结构。
- 替换样式系统。

这些动作必须有调用方检查和回归验证。
