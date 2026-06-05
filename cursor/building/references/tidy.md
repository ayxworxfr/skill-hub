# Tidy 子模式详解

子模式 = `tidy`（结构改、不改 user-visible 行为）。配合 building/SKILL.md 共用骨架使用。

锚定方法论：Kent Beck *Tidy First?* (O'Reilly 2023)。

## 核心原则

tidy = **小步、可逆、不改行为**的结构整理。每次 tidy 单独 commit，跑现有测试保持绿。

tidy 是为后续 feature / fix 让路而做的就近整理，**不是大重构**。大重构（跨多文件 / 改抽象层 / 涉及多模块迁移）→ 用 `refactoring` skill。

S/B 拆分顺序由 building 主文 Step 7 + plan 卡指定；本 reference 只规定 tidy 子模式产出**什么样的 S 类**。

## tidy vs refactoring vs feature

| 维度 | tidy（本子模式） | refactoring skill | feature 子模式 |
|---|---|---|---|
| 是否改行为 | 否 | 否 | 是 |
| 范围 | 单文件 / 紧邻函数 | 跨文件 / 跨模块 | 按任务契约 |
| 一次时长 | 分钟级 | 半天 ~ 多天 | 按切片 |
| 触发场景 | 改 X 前 X 周边乱 | 整体结构债重 | 新需求 / 修 bug |
| commit message | `tidy:` | `refactor:` | `feat:` / `fix:` |

简单判断：**接下来要改某段代码，你想先整理一下让改动更顺手** → tidy。**要重新组织整片模块** → refactoring skill。

## 常见 tidy 动作（Beck 列表精简）

每条都满足"不改 user-visible 行为 + 现有测试保持绿"：

| 动作 | 说明 |
|---|---|
| **抽函数（Extract Function）** | 把一段有名字的逻辑抽出来命名清楚 |
| **内联函数（Inline Function）** | 一次性使用且名字没增加信息的函数收回去 |
| **重命名（Rename）** | 让名字反映意图（变量 / 函数 / 文件） |
| **就近移动（Move Closer）** | 相关代码挪到一起；删掉的留下空隙补回 |
| **删 dead code** | 没人调用的 / 永远不会执行的分支 |
| **加 guard clause** | 早返回，减少嵌套 |
| **对称化（Symmetrize）** | 相似的代码长得一样（同样命名、同样顺序、同样错误处理） |
| **解释性变量** | 复杂表达式拆成命名变量 |
| **分块（Chunk）** | 把一坨堆在一起的代码用空行分块 |
| **新接口的旧实现** | 想要的接口先写出来，旧实现适配过去 |

## 强制规则

### 1. 不改 user-visible 行为

- 函数签名（参数、返回类型）保持
- 错误码、错误消息保持
- 日志输出保持
- 性能数量级保持
- 序列化 / 持久化格式保持

任何一条改了 → 不是 tidy，是 B 类。

### 2. 现有测试必须全绿

tidy 前后都跑一次测试。**禁止**：

- 改测试以适配 tidy（说明 tidy 改了行为）
- 跳过 / 注释测试
- "测试改一下让它过"

### 3. 一次一个 tidy

每个 tidy 动作单独 commit。多个 tidy 可以连续做，但**不要塞同一个 commit**。

### 4. 范围边界

如果发现 tidy 越做越大（跨多文件 / 涉及抽象层 / 涉及调用方）→ 停下，转去用 `refactoring` skill 规划。

## tidy 专属禁止输出

主文"共用禁止输出"已覆盖"结构和功能一起改"等通用项；以下是 tidy 子模式补充：

| 禁止 | 替代 |
|---|---|
| "顺便修了个 bug" | 拆出来：tidy commit + 单独 fix commit |
| "顺便加了个参数" | 拆出来：tidy commit + 单独 feat commit |
| "测试改一下让它过" | tidy 不允许；改测试 = 改了行为 |
| "整体重新组织一下" | 转 refactoring skill |
| "应该不会有副作用" | 跑测试 + 检查日志字面值 |
| "改了一些命名" | 列具体 rename 列表 + grep 验证 |

## 输出片段

```markdown
## tidy 动作

- 类型：抽函数 / 重命名 / 删 dead code / ...
- 范围：<文件:函数 列表>
- 行为是否变化：否（核对：签名 / 错误码 / 日志 / 序列化）

## 验证

- 现有测试：<命令> → 全绿
- 日志 / 错误消息字面值：未变（diff 检查）

## commit

- message：`tidy: <动作描述>`
- 与后续 feature commit 分开
```
