---
title: EVM 执行模型基础
date: 2026-07-14
draft: false
tags: [EVM, Learning, Security]
categories: [学习笔记]
---

理解 EVM 的调用帧、存储和消息字段，有助于解释许多看似“Solidity 语法”的安全问题。

<!--more-->

## 关键概念

- `call` 创建新的执行上下文；`delegatecall` 复用调用者的存储。
- `msg.sender`、`msg.value` 和 `address(this)` 会随调用方式改变。
- storage 是持久状态，memory 只在当前调用帧有效。

可使用 Mermaid 短代码记录调用关系：

{{< mermaid >}}
flowchart LR
  User --> Proxy
  Proxy -->|delegatecall| Implementation
{{< /mermaid >}}
