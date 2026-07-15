---
title: "Unchecked Low Level Calls"
date: 2026-07-14
publishDate: 2026-07-14
draft: false
---

## 未检查的低级调用

**低级调用的函数都包括：**

`send()` `call()` `delegatecall()` `staticcall()`

**在调用这些函数时，如果发生异常会返回bool值，而在具体合约代码中并没有检查返回的bool值，即使报错程序也不会终止，会继续往下执行**

### `call()`:

向合约转账(这个用法见到的次数比较多)

`(bool success, ) = address(target).call{value:ETH金额}("") `

用来调用函数,需要使用abi.encodeWithSignature（到目前为止还没怎么用）

使用规则：在不知道目标合约的代码，或者没有引入目标合约的interfance时，想要调用该函数

`(bool success,bytes memory data) = address(target).call(abi.encodeWithSignature("transfer(address,uint256)", recipient, amount))`

函数签名；`"transfer(address,uint256)"`
动态参数：`recipient, amount`，第一个是address类型的变量，第二个是一个uint256类型的变量。

### `delegatecall()`:

调用方法和call基本一致

借用目标合约代码，在当前合约环境中运行

delegatecall不可以进行转账

### `staticcall()`:

只进行只读调用，不允许修改状态

用法：

`(bool success, bytes memory data) = targetAddress.staticcall(abi.encodeWithSignature("getBalance(address)", userAddress));`



**防范方法： 在调用之后使用require接收返回值**
