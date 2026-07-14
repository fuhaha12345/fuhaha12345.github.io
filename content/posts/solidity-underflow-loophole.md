---
title: 整数下溢漏洞
date: 2026-04-20
draft: false
description: 通过一个 Solidity 0.6.0 示例理解整数下溢漏洞的成因、利用条件与修复方式。
tags:
  - Solidity
  - 智能合约安全
  - 整数下溢
categories:
  - 漏洞分析
series:
  - Solidity 漏洞分析
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

contract loophole{

    mapping(address => uint256) balances;
    mapping(string => uint256) prices;
    bool record;

// 在 Solidity 0.6.0 版本中，编译器强制要求构造函数必须声明可见性,Solidity 0.7.0 及以后版本才不需要

    constructor() public payable{
        prices["nailong"] = 1e6 ether;
    }

    function overflow(uint256 _money) public{
        require(_money < 1e5,"Failed");
        balances[msg.sender] -= _money;
        require(balances[msg.sender] > 1e6 ether,"Insufficient balance");
        require(record == false,"you have already made a purchase");
        balances[msg.sender] -= prices["nailong"];
        record = true;
    }

    function check_balances(address _depositor) public view returns(uint256){
        return balances[_depositor];
    }
}
```

## 漏洞原理

在 Solidity 0.8.0 之前，`uint256` 的算术运算默认不会检查下溢。当余额为 `0` 时执行 `balances[msg.sender] -= 1`，数值会回绕为一个非常大的整数，从而绕过后续的余额校验。

本例中，`overflow` 在扣减前没有确认用户余额足够，攻击者可以传入一个很小的 `_money`，令余额下溢，再满足购买条件。

## 利用脚本

对应的 Foundry 脚本已移至 [`examples/solidity-underflow/Attack.s.sol`](https://github.com/fuhaha12345/fuhaha12345.github.io/blob/main/examples/solidity-underflow/Attack.s.sol)，避免被 Hugo 当作文章内容处理。

## 修复建议

- 使用 Solidity `^0.8.0`，让编译器默认检查整数溢出和下溢。
- 在扣减前显式校验余额，例如 `require(balances[msg.sender] >= _money, "Insufficient balance")`。
- 对关键状态变更编写单元测试，覆盖零余额和边界输入。
