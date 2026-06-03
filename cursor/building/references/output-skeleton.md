# Building 输出骨架

building skill 的输出统一遵循以下骨架。子模式（feature / test / config / tidy）按各自 reference 追加片段。

## 完整骨架

```markdown
## 子模式

- <feature / test / config / tidy，多选时按出现顺序>

## 任务契约

- 来自执行卡：<对齐卡 / 方案卡 / 设计卡 / 切片 ID>，或自写
- 目标：
- 非目标：
- 输入 / 输出 / 验收：
- diff 预算：<文件数> / <行数>

## 实施

- 改了什么行为：
- 复用的项目模式：<具体文件:函数>
- 删除 / 适配的旧逻辑：
- 调用方 grep 验证（公开接口）：

## 失败模式与 RED 测试

- 引用失败模式表：F-1, F-3
- 写了哪些 RED 测试：
- 现在状态：绿 / 仍红（说明）

## commit 拆分

- S 类（tidy）：commit 1, 2 ...
- B 类（feat / fix / config）：commit 3, 4 ...

## 验证

- 已运行：<命令>
- 结果：
- 覆盖路径：
- 未验证：

## 残留

- <未验证项 / 越界检测 / 风险；没有写"无">
```

## 子模式追加片段

| 子模式 | 追加片段 reference |
|---|---|
| test | [writing-tests.md](writing-tests.md) `## test 输出片段` |
| config | [config-changes.md](config-changes.md) 输出部分 |
| tidy | [tidy.md](tidy.md) `## 输出片段` |

feature 子模式无独立追加片段，按主骨架输出即可。

## 不能省的核心字段

无论子模式都不能省：

- 任务契约（目标 / 非目标 / 输入输出验收 / diff 预算）
- 实施（行为变更 + 复用模式引用 + 调用方 grep 验证）
- 验证（具体命令 + 结果）
- 残留（无残留写"无"是逃逸；要么写未验证项，要么写"已全验证"+证据）
