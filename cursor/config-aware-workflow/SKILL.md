---
name: config-aware-workflow
description: Edits code with configuration awareness by checking related config files, runtime paths, and environment assumptions before changing behavior. Use when modifying systems driven by YAML, JSON, env vars, file paths, schedules, feature flags, or runtime configuration.
---

# Config Aware Workflow

## 目标

避免“只改代码不看配置”导致的假修复。

## 工作流

### 1. 找配置来源

- 先确认行为是由代码、配置、环境变量还是运行参数决定
- 查找相关 `yml`、`yaml`、`json`、`.env`、常量定义、路径配置

### 2. 建立映射

- 配置项名是什么
- 在哪里读取
- 传到了哪些对象或函数
- 最终影响哪个分支或输出

### 3. 修改时同步检查

- 改字段名时，同时检查读取方和使用方
- 改路径时，同时检查目录创建、文件命名、下游消费方
- 改开关时，同时检查默认值和缺省行为

### 4. 验证

- 至少验证一个正常场景
- 如有条件，再验证一个缺省或异常场景

## 适用信号

- 用户提到配置文件
- 改动涉及环境变量、文件路径、运行参数
- 系统行为依赖 YAML/JSON
- 代码本身没问题，但运行结果不符合预期
