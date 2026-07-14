---
title: "Oracle 价格操纵"

date: 2026-07-14

draft: false

description: "分析 DeFi 中价格预言机失效导致的攻击，以及多源预言机和 TWAP 的设计要点。"

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

预言机决定了链上协议如何把资产数量映射为价值。价格源被操纵时，借贷、清算和铸币的经济边界都会失效。

<!--more-->

## 漏洞背景

小流动性池的即时价格可以被大额交易显著改变。若协议直接使用该价格计算抵押价值，攻击者可制造虚高或虚低估值。

## 漏洞代码

```solidity
function price() public view returns (uint256) {
    return reserveQuote * 1e18 / reserveBase; // 可被当前交易改变
}
```

## 攻击流程

1. 攻击者通过交换暂时扭曲池子储备。
2. 目标协议读取扭曲后的即时价格。
3. 攻击者以虚高抵押借出资产，或触发错误清算。
4. 价格恢复后，协议留下坏账或损失。

## 修复方案

- 采用 Chainlink 等独立价格源，并检查心跳与价格新鲜度。
- 对 AMM 价格使用足够窗口的 TWAP，并要求最低流动性。
- 对价格偏差设置断路器和人工应急路径。

## 安全建议

价格安全不仅是公式正确，还包括数据延迟、流动性、更新频率和极端行情下的降级行为。
