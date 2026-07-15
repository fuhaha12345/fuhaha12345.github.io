---
title: 闪电贷攻击原理
date: 2026-07-14
draft: false
description: 闪电贷如何放大单交易内的资金能力，以及协议应如何设计状态和价格防线。
tags: [DeFi, Security, Flashloan]
categories: [DeFi 安全]
series: [DeFi 安全研究]
---

闪电贷本身是无抵押的原子流动性工具，不是漏洞。问题在于协议把“单笔交易内可操纵的状态”误认为可靠输入。

<!--more-->

## 漏洞背景

当抵押率、投票权、兑换价格或清算条件直接读取同一交易中可改变的池子余额时，攻击者可临时借入巨量资产改变结果。

## 攻击流程

1. 借入目标资产。
2. 在同一交易内改变 AMM 储备、抵押余额或治理权重。
3. 调用依赖该状态的敏感函数获利。
4. 归还闪电贷，保留差额。

## 漏洞代码

```solidity
function collateralValue(address user) public view returns (uint256) {
    return balances[user] * pool.getSpotPrice(); // 单点现货价格
}
```

## 修复方案

- 用时间加权平均价格（TWAP）或多源预言机替代即时现货价。
- 对高价值参数更新设置延迟、上限和异常检测。
- 将治理投票快照与可借流动性隔离。

## 安全建议

威胁建模时假设攻击者在一笔交易里拥有无限短期流动性；任何依赖瞬时余额的权限或价格计算都应重新评估。
