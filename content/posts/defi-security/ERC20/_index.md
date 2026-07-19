---
title: "ERC20"

date: 2026-07-19

draft: false

description: "分析 ERC20中存在的主要函数,以及存在的安全隐患"

categories:
- DeFi安全

tags:
- defi
- security
- oracle
- flashloan

series:
- DeFi安全研究
---

### ERC20

是以太坊上的代币标准，它实现了代币转账的基本逻辑：

接口为`IERC20`，接口函数中的函数都符合ERC20的规则，而且只需要函数名称，输入参数，输出参数即可。

`IERC20`定义了6个函数：

返回代币总供给

```
function totalSupply() external view returns (uint256);	
```

返回账户余额

```
function balanceOf(address account) external view returns (uint256);
```

转账

```
function transfer(address to, uint256 amount) external returns (bool);
```

`allowance()`返回授权额度

```
function allowance(address owner, address spender) external view returns (uint256);
```

`approve()`授权

Token持有人授权第三方使用自己的Token，只是授权，不会转账

```
function approve(address spender, uint256 amount) external returns (bool);
```

`transferFrom()`授权转账

- 我授权别人，然后别人帮我转钱。

```
function transferFrom(
    address from,
    address to,
    uint256 amount
) external returns (bool);
```

有两个函数不在IERC20标准中，mint()函数和burn()函数，一个是铸造代币函数，一个是销毁代币函数

如果该代币设计为限量发行，任何人都能调用 `mint()` 就属于严重的访问控制漏洞。

```
function mint(uint amount) external {
    balanceOf[msg.sender] += amount;
    totalSupply += amount;
    emit Transfer(address(0), msg.sender, amount);
}
```

```
function burn(uint amount) external {
    balanceOf[msg.sender] -= amount;
    totalSupply -= amount;
    emit Transfer(msg.sender, address(0), amount);
}
```

常见的 ERC20 实现使用两个 mapping 分别记录余额和授权额度。

```
mapping(address => uint256 ) public override balanceOf;
mapping(address => mapping(address => uint256)) public override allowance;
```

ERC20中的两个重要事件

```
event Transfer(address indexed from,address indexed to,uint256 value);
// 记录授权了别人多少Token
event Approval(address indexed owner,address indexed spender,uint256 value);
```

按WTF的简单写了一个铸币合约

```
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Mytoken is IERC20{
    mapping(address => uint256 ) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    string public name;
    string public symbol;
    uint256 public override totalSupply;
    
    constructor(string memory _name,string memory _symbol){
        name = _name;
        symbol = _symbol;
    }


    function transfer(address recipient, uint256 amount) external overide returns(bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(msg.sender,recipient,amount);
        return true;
    }


    function approve(address spender,uint256 amount) external overide returns(bool){
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender,spender, amount);
        return true;
    }

    function transferFrom(address sender,address recipient,uint256 amount) external overide returns(bool){
        allowance[sender][msg.sender] -= amount;
        balanceOf[sender] -= amount;
        balanceOf[recipient] += amount;
        emit Transfer(sender, recipient, amount);
        return true;
    }

    function mint(uint256 amount) external{
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
    }

    function burn(uint256 amount) external{
        balanceOf[msg.sender] -= amount;
        totalSupply -= amount;
        emit Transfer(msg.sender,address(0),amount);
    }

}
```

![image-20260717204950859](../AppData/Roaming/Typora/typora-user-images/image-20260717204950859.png)

![image-20260717204856379](../AppData/Roaming/Typora/typora-user-images/image-20260717204856379.png)

成功使账户余额变为100

#### 常见的安全问题

我写的铸币合约就存在安全问题，别人可以无限铸币，应该限制admin权限，加修饰器也可以

- 无限增发漏洞

```
function mint(uint256 amount) external{
        balanceOf[msg.sender] += amount;
        totalSupply += amount;
        emit Transfer(address(0),msg.sender,amount);
}
```

- 权限控制问题

```
function setMinter(address user) external {
    minter = user;
}
```

任何人都可以成为minter无限铸币，

- approve授权问题

```
approve(DEX,type(uint256).max);
```

这代表DEX可以无限的花我的Token，应该限制额度或定期取消授权
