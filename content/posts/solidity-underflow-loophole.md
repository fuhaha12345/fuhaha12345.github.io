---
title = '整数下溢漏洞'
draft = false
tags = ['Solidity','智能合约安全']
---
```solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.6.0;

contract loophole{

    mapping(address => uint256) balances;
    mapping(string => uint256) prices;
    bool record;

// 在 Solidity 0.6.0 版本中，编译器强制要求构造函数必须声明可见性,Solidity 0.7.0 及以后版本才不需要

    constructor() public payable{
        prices["nailong"] = 1e6 ether;
    }

    function overflow(uint256 _money) public{
        require(_money < 1e5,"Failed");
        balances[msg.sender] -= _money;
        require(balances[msg.sender] > 1e6 ether,"Insufficient balance");
        require(record == false,"you have already made a purchase");
        balances[msg.sender] -= prices["nailong"];
        record = true;
    }

    function check_balances(address _depositor) public view returns(uint256){
        return balances[_depositor];
    }
}
