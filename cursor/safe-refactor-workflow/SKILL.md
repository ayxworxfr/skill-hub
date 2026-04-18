---
name: safe-refactor-workflow
description: Refactors existing code without changing intended behavior by identifying external behavior, protecting it with focused validation, simplifying structure, and checking for regressions. Use when the user asks to refactor, clean up, reorganize, extract shared logic, or improve structure without changing outcomes.
---

# Safe Refactor Workflow

## 目标

在不改变预期行为的前提下，整理代码结构、降低复杂度、提升可维护性。

## 适用范围

优先用于以下场景：

- 用户说“重构”
- 用户说“整理一下结构”
- 用户说“抽一下公共逻辑”
- 用户说“优化代码，但不要改行为”

## 工作流

### 1. 先识别外部行为

- 哪些输入输出必须保持不变
- 哪些异常、返回值、文件格式、字段名必须保持不变
- 哪些调用方依赖当前行为

### 2. 建立保护

- 优先复用现有测试保护行为
- 如果关键路径没有保护，补最小回归验证
- 先确认行为，再动结构

### 3. 只做一种主要重构

一次重构尽量只聚焦一个目标：

- 拆大函数
- 消除重复
- 收敛条件分支
- 提升命名清晰度
- 整理模块职责

### 4. 控制改动面

- 不把需求变更混进重构
- 不顺手修改大量无关代码
- 不为了“更优雅”引入过度抽象

### 5. 立刻验证

- 跑最小相关测试
- 检查调用路径是否仍然成立
- 检查是否引入新的 lint 或导入错误

## 决策原则

- 优先清晰，不优先炫技
- 优先小步稳定演进
- 优先减少重复和嵌套层级
- 优先保留已有模块边界，除非边界本身就是问题

## 常见可接受动作

- 提炼辅助函数
- 合并重复分支
- 删除无用代码
- 收敛重复常量和映射
- 优化函数命名和局部变量命名

## 常见危险动作

- 一边重构一边改需求
- 把简单逻辑过度抽象成很多层
- 改动大量文件却没有保护性验证
- 在不了解调用方时修改公共函数签名

## 输出要求

汇报时应说明：

- 保持不变的行为是什么
- 结构上做了什么整理
- 用什么方式验证没有回归
- 还有哪些未覆盖风险

## 触发信号

- “重构”
- “优化结构”
- “代码太乱了整理一下”
- “抽公共逻辑”
- “不要改行为”
