---
title: Solidity 安全基础
date: 2026-07-14
draft: false
tags: [Solidity, Learning, Security]
categories: [学习笔记]
---

Solidity 安全从理解状态、调用上下文和失败语义开始。

<!--more-->

## 三个基本问题

1. 这段代码在谁的存储中执行？
2. 外部调用是否允许控制流回到当前合约？
3. 失败时状态是否会完整回滚？

写代码时优先使用显式权限、清晰错误信息和可测试的不变量；审计时再验证这些假设是否始终成立。
