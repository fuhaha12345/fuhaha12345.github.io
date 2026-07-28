---
title: "Creation Code"
date: 2026-07-28
publishDate: 2026-07-28
draft: false
---

## creation code

编译一个solidity合约，生成的字节码包括两部分

`creation code（创建代码） + runtime code（运行时代码）`

- Creation Code：只在部署时执行一次，负责完成初始化，并返回 runtime code。
- Runtime Code：真正存储在区块链上的合约代码，后续所有调用都执行这部分。

### Creation code 和 runtime code 的区别

| 项目                   | Creation code                 | Runtime code          |
| ---------------------- | ----------------------------- | --------------------- |
| 执行时间               | 部署时执行一次                | 每次调用合约时执行    |
| 是否包含 constructor   | 包含                          | 不包含                |
| 最终是否存储在合约地址 | 否                            | 是                    |
| Solidity 获取方式      | `type(C).creationCode`        | `type(C).runtimeCode` |
| 主要作用               | 初始化状态并返回 runtime code | 处理日常函数调用      |

基本的流程：

```
creation code + constructor 参数
              │
              ▼
       EVM 执行 creation code
              │
       执行 constructor
              │
       RETURN runtime code
              ▼
runtime code 被永久存入合约地址
```

假设存在一个合约：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

contract Child {
    uint256 public immutable value;
    address public immutable creator;

    constructor(uint256 value_) {
        value = value_;
        creator = msg.sender;
    }
}
```

部署时，交易的 `data` 大致是：

```
bytes memory initCode = abi.encodePacked(type(Child).creationCode,abi.encode(value));
```
