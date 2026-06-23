# 六维度审查细化

配合 reviewing-code/SKILL.md §2.3 使用。每个维度独立过，必须给出"已检查"或具体 finding。

与 building/SKILL.md §3.1 R 表联动：正确性维度含 R1-R7 全部检查入口。

---

## 1. 正确性

目标：逻辑、边界、空值、异常、并发、时序。

**检查动作**：

1. 列出所有改动函数的入参组合，逐一确认边界值处理（null / empty / 0 / 负数 / 超大值）
2. 追踪每条数据路径：输入→处理→输出，确认中途无静默丢弃（R2 silent fake success）
3. 检查 try-except / try-catch：有无吞掉异常（`except: pass` / `catch(e) {}`）而不处理根因
4. 确认 API / import / 库是否在 lockfile 里实际存在（R1 hallucination）
5. 检查并发路径：共享状态是否有竞态条件、锁范围是否正确
6. 检查时序依赖：是否依赖"某操作先完成"但无强制保证（如两个异步任务）
7. 扫描 TODO / FIXME / XXX / `print(` / `console.log(` 调试残留（scan_review_signals.py 会标出候选）

**命中模式（命中 → 升 finding）**：

| 模式 | 对应 R 表 | 典型代码 |
|---|---|---|
| `except: pass` / `except Exception: pass` | R2 | `try: save() except: pass` |
| 函数 return None 但调用方未判断 | R2 | `result = get_user(); result.name` |
| 直接用 assert 做生产路径校验 | — | `assert user_id > 0` |
| 直接 import 不存在的库 | R1 | lockfile 无对应包名 |
| 并发写共享变量无 lock | — | 两个协程写同一个 dict |
| `time.sleep()` 替代事件等待 | — | 轮询替代回调/等待 |

**典型 finding 模板**：

```
[Critical] `service.py:42`
- 问题：try-catch 吞掉了数据库写失败的异常，调用方拿到 None 误以为写入成功
- 影响：写失败时数据静默丢失，无任何告警
- 触发场景：数据库连接超时或主键冲突时
- 修复方向：显式捕获并重新抛出，或返回错误状态让调用方处理
```

**不属于本维度**：API 设计/职责划分（→ 结构）；测试是否覆盖（→ 验证）；注入/权限（→ 安全）

---

## 2. 回归

目标：旧行为、调用方、兼容接口、持久化数据。

**检查动作**：

1. 列出改动的公开 API / 函数签名 / 返回类型，逐一 grep 调用方确认兼容
2. 确认删除/改名的字段、函数、常量在所有调用位置都同步更新（R5 inconsistent edit）
3. 检查数据库迁移：新列有默认值 / 旧数据 backfill 逻辑 / 迁移是否可回滚
4. 检查持久化数据格式变化：JSON schema / protobuf / config 文件格式是否向后兼容
5. 运行 `git log --oneline -20 -- <file>` 确认改动文件近期有无相关上下文
6. 检查 feature flag：改动是否在 flag 保护下 / flag 关闭时旧路径是否完整

**命中模式**：

| 模式 | 对应 R 表 | 判断 |
|---|---|---|
| 改了函数签名，未 grep 调用方 | R5 | Critical：调用方编译 / 运行时崩 |
| 删列无 migration | — | Critical：数据丢失 |
| 新增 NOT NULL 列无 default | — | Critical：历史数据回滚失败 |
| 返回类型从 T 改为 T? / T | None 未通知调用方 | R5 | Major |
| 枚举新增值，switch 无 default 分支 | — | Major |

**典型 finding 模板**：

```
[Critical] `user_service.py:18`
- 问题：get_user() 返回值从 User 改为 Optional[User]，但 auth_middleware.py:34 未更新，直接访问 .id
- 影响：用户不存在时 AttributeError 崩溃，影响所有鉴权路径
- 触发场景：传入不存在的 user_id 时
- 修复方向：auth_middleware.py:34 加 None 判断，或抛出明确 404
```

**不属于本维度**：逻辑边界（→ 正确性）；注入/权限（→ 安全）；测试覆盖（→ 验证）

---

## 3. 数据

目标：字段、类型、单位、排序、过滤、聚合、时区、精度。

**检查动作**：

1. 检查货币 / 金融字段：是否用浮点数（float/double）而非定点数 / Decimal
2. 检查时间字段：存储时区（UTC / local）/ 展示时区是否一致，跨时区场景是否处理
3. 检查排序和分页：offset 分页在数据插入时是否会导致重复/遗漏（→ cursor 分页）
4. 检查过滤逻辑：null 字段在过滤条件下的行为（IS NULL vs = NULL 的语义差）
5. 检查聚合：GROUP BY 字段与 SELECT 字段是否一致（特别是 MySQL non-strict mode）
6. 检查精度截断：int 溢出 / float 精度丢失 / string 截断未校验长度

**命中模式**：

| 模式 | 风险 |
|---|---|
| `price * quantity` 用 float | 货币精度误差，财务对账失败 |
| `datetime.now()` 无时区 | 多时区部署数据错乱 |
| `ORDER BY created_at` 但 created_at 有重复值 | 分页结果不稳定 |
| `SUM(amount)` 含 NULL 行 | NULL 传播导致总和为 NULL |
| 直接截断 string 未校验 byte 长度 | 多字节字符截断产生乱码 |

**典型 finding 模板**：

```
[Major] `order_calc.py:67`
- 问题：total = price * quantity 使用 float 乘法，累计 1000 单后精度误差可达 ±$0.50
- 影响：财务对账误差，批量结算时金额对不上
- 触发场景：price 含小数（如 $9.99）且批量聚合时
- 修复方向：改用 Decimal(str(price)) * quantity，或在数据库层保留 NUMERIC 类型
```

**不属于本维度**：SQL 注入（→ 安全）；字段命名（→ 结构）；聚合测试（→ 验证）

---

## 4. 结构

目标：职责边界、重复、抽象、依赖方向。

**检查动作**：

1. 确认改动是否引入循环依赖（A import B，B import A）
2. 检查单一职责：一个函数 / 类是否同时承担 IO、业务逻辑、格式化，混合 → Major
3. 对照 building skill 的 code-craftsmanship.md：U 信号（欠抽象）/ O 信号（过抽象）双向扫
4. 检查重复代码：是否新增了与现有函数相似的逻辑（>3 处出现 → 该抽）
5. 检查依赖方向：domain 层是否引入了 infra / presentation 层的东西

**命中模式**：

| 模式 | 对应信号 | 判断 |
|---|---|---|
| 新增函数签名 ≥5 参数 | U2 | Major：应抽 Model / 参数对象 |
| 同类操作 ≥3 处复制 | U3 | Major：应抽函数 |
| 用了 Factory/Strategy/Manager 但只有 1 个实现 | O1 | Minor：删包装或等第 2 个实现 |
| domain model import了 HTTP request 对象 | — | Major：依赖方向逆转 |
| 函数 >40 行混合 IO 和业务逻辑 | — | Major：拆职责 |

**典型 finding 模板**：

```
[Major] `user_handler.py:88`
- 问题：handle_register() 同时做 HTTP 解析、业务校验、DB 写入、发邮件，单函数 80 行
- 影响：任一步骤改动都需要理解全部流程，测试无法隔离单层
- 触发场景：每次注册请求都经过该函数
- 修复方向：拆为 parse_request / validate / save_user / notify，各自单测
```

**不属于本维度**：具体算法逻辑（→ 正确性）；注入（→ 安全）；测试有无（→ 验证）

---

## 5. 安全

目标：输入验证、注入、权限、秘密、路径、XSS/CSRF。

**检查动作**：

1. 检查所有外部输入（HTTP 参数 / 表单 / 文件名 / 环境变量）：是否进入 SQL / shell / 文件路径前做了参数化或白名单
2. 检查权限边界：API 端点是否有鉴权 / 授权；用户 A 能否访问用户 B 的数据（IDOR）
3. grep 新增的 secret / key / token / password 字段：是否硬编码在源码 / 是否误入 log
4. 检查文件路径操作：是否存在 path traversal（`../../../etc/passwd`）
5. 检查前端输出：用户输入是否 raw innerHTML / dangerouslySetInnerHTML（XSS）
6. 检查新增的跨域 / 状态改变 API：是否有 CSRF token 或 SameSite cookie

**命中模式**：

| 模式 | 风险 | 等级 |
|---|---|---|
| `f"SELECT * FROM users WHERE id={user_id}"` | SQL 注入 | Critical |
| `subprocess.run(user_input, shell=True)` | RCE | Critical |
| `os.path.join(base, user_input)` 无 normpath / startswith 校验 | 路径穿越 | Critical |
| API key / token 硬编码 | 密钥泄漏 | Critical |
| `res.innerHTML = userInput` | XSS | Major |
| 未验证 JWT signature 就解 payload | 越权 | Critical |
| logger.info(f"password={password}") | 敏感信息泄漏 | Major |

**典型 finding 模板**：

```
[Critical] `api/files.py:23`
- 问题：os.path.join(BASE_DIR, request.args['path']) 未校验，可穿越到 BASE_DIR 外
- 影响：攻击者读取服务器任意文件（/etc/shadow、.env 等）
- 触发场景：path 参数含 ../ 序列时
- 修复方向：normalize 后用 os.path.abspath 检查是否以 BASE_DIR 开头，不满足则 403
```

**不属于本维度**：密码哈希算法选型（→ 结构讨论）；测试安全路径（→ 验证）

---

## 6. 验证

目标：测试覆盖、构建、lint、手动路径。

**检查动作**：

1. 列出改动的核心逻辑路径，确认对应测试用例存在且覆盖正常 + 异常两条路径
2. 检查是否存在 R7（修测试让代码通过）：测试断言是否被软化（`assert result is not None` 替代 `assert result == expected`）
3. 确认 CI/CD 状态（如有 PR）：build / lint / type check 是否通过
4. 检查新增功能是否缺少 integration test（特别是 migration / 外部 API 调用路径）
5. 检查手动复现路径是否在 PR description 有记录；若无，补 Open Questions

**命中模式**：

| 模式 | 对应 R 表 | 判断 |
|---|---|---|
| 改动函数无对应测试 | — | Major（核心路径） / Minor（边缘） |
| 断言从 `assertEqual(x, 5)` 改为 `assertIsNotNone(x)` | R7 | Major |
| 删除测试文件/用例 | — | Critical（若非故意淘汰） |
| migration 无测试跑回滚场景 | — | Major |
| PR description 无手动验证步骤 | — | Minor（可在 Open Questions 提示） |

**典型 finding 模板**：

```
[Major] `tests/test_payment.py:55`
- 问题：断言从 assertEqual(result.status, "SUCCESS") 改为 assertIsNotNone(result)，覆盖弱化
- 影响：payment 状态返回错误值时测试仍通过，无法检测回归（R7）
- 触发场景：payment 网关返回非 SUCCESS 状态码时
- 修复方向：恢复 assertEqual，或增加对 status 字段的明确断言
```

**不属于本维度**：测试代码自身的逻辑问题（→ 正确性）；CI 配置结构（→ 结构）

---

## 维度间优先级

多条 finding 时按以下顺序评估影响范围：

1. **安全** > **正确性** > **回归** > **数据** > **验证** > **结构**（等级相同时优先处理左侧）
2. 一个问题只归入最相关的维度，不跨维度重复 finding
3. 某维度未命中时，输出"已检查，未发现"——不能省略（P3）
