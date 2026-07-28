---
title: "Solidity Gas 优化"
date: 2026-07-28
publishDate: 2026-07-28
draft: false
---

Gas 优化应优先保证代码正确、清晰，并通过测试和 Gas 报告验证实际收益。不同编译器版本、优化器配置和调用场景可能产生不同结果。

## 一、存储操作优化

### 1. 减少 Storage 读写

`SLOAD` 和 `SSTORE` 通常比栈或内存操作昂贵。循环中需要重复使用状态变量时，可以先读取到局部变量，完成计算后再统一写回。

```solidity
uint256 public counter;

function addMany(uint256 n) external {
    uint256 value = counter; // 一次 SLOAD

    for (uint256 i; i < n; ++i) {
        ++value;
    }

    counter = value; // 一次 SSTORE
}
```

如果在循环中反复执行 `counter = counter + 1`，每次迭代都会访问 Storage，成本会明显增加。

### 2. 变量打包

一个 Storage 槽为 32 字节。相邻的小类型状态变量在总长度不超过 32 字节时，可以被编译器打包进同一个槽。

```solidity
// 这三个变量可以打包到同一个 Storage 槽
uint128 a; // 16 字节
uint64 b;  // 8 字节
uint64 c;  // 8 字节
```

变量顺序会影响打包结果，应尽量把可以组合的小类型放在一起。

小类型并非在所有场景都更省 Gas。对于局部计算或单独占槽的状态变量，`uint256` 通常更适合 EVM 的 256 位字长；`uint8` 等类型可能增加掩码和类型转换操作。

### 3. 使用 `constant` 和 `immutable`

`constant` 的值会在编译时确定，`immutable` 的值会在部署时确定。两者都不占用普通状态变量的 Storage 槽，读取通常比普通状态变量便宜。

```solidity
uint256 public constant FEE_DENOMINATOR = 10_000;
address public immutable owner;

constructor(address owner_) {
    owner = owner_;
}
```

## 二、数据类型选择

### 1. 根据存储和计算场景选择整数类型

EVM 的自然操作字长是 256 位。局部计算通常使用 `uint256`；只有在能够与其他状态变量打包时，`uint8`、`uint16`、`uint32` 等小类型才可能节省 Storage。

### 2. 使用 `bytes32` 保存固定长度短数据

当数据长度固定且不超过 32 字节时，`bytes32` 通常比动态长度的 `string` 更容易控制存储成本。但它不适合任意长度文本，并且需要额外处理编码和显示。

### 3. 根据访问方式选择 `mapping` 或数组

`mapping` 适合按键直接查找，不保存长度，也不能直接遍历；动态数组保存长度并支持按顺序枚举。二者的选择应由数据访问方式决定，不能简单认为 `mapping` 在所有情况下都更便宜。

```solidity
uint256[] public list;
mapping(uint256 => uint256) public values;
```

## 三、函数与数据位置

### 1. 合理选择 `external` 和 `public`

只需要从合约外部调用的函数可以声明为 `external`；还需要在合约内部直接调用时，可以声明为 `public`。对于动态参数，是否使用 `calldata` 往往比单纯比较 `external` 和 `public` 更重要。

```solidity
function process(uint256[] calldata data) external {
    // 直接读取只读 calldata，不复制到 memory
}
```

### 2. 只读动态参数优先使用 `calldata`

`calldata` 是只读数据区域。函数不需要修改动态参数时，使用 `calldata` 可以避免将参数整体复制到 Memory。

```solidity
function sum(uint256[] calldata values) external pure returns (uint256 total) {
    for (uint256 i; i < values.length; ++i) {
        total += values[i];
    }
}
```

## 四、其他常用方法

### 1. 谨慎使用 `delete`

`delete` 会把值重置为类型默认值。把非零 Storage 槽清零可能产生 Gas 退款，但退款规则和上限已经收紧，不应为了退款而增加无意义的写操作。

```solidity
mapping(address => uint256) public balances;

function clearBalance() external {
    delete balances[msg.sender];
}
```

对于动态数组，`pop()` 已经会清除最后一个元素并缩短数组，不需要先对最后一个元素执行 `delete`。

```solidity
uint256[] public data;

function removeLast() external {
    data.pop();
}
```

### 2. 使用自定义错误代替错误字符串

自定义错误可以减少部署字节码和回退数据大小，并允许携带结构化参数。

```solidity
error InsufficientBalance(uint256 available, uint256 required);

if (balance < amount) {
    revert InsufficientBalance(balance, amount);
}
```

### 3. 确认安全后使用 `unchecked`

Solidity 0.8+ 默认检查整数溢出和下溢。只有能够证明运算不会越界时，才应使用 `unchecked` 跳过检查。

```solidity
function increment(uint256 value) external pure returns (uint256) {
    require(value < type(uint256).max);

    unchecked {
        return value + 1;
    }
}
```

## 五、测量优化结果

不要只凭经验判断优化是否有效。使用相同的编译器版本和优化器配置，对修改前后的实现运行测试并比较 Gas 数据。

```bash
forge test --gas-report
forge snapshot
```

优化完成后还应保留完整的功能测试，避免为了减少少量 Gas 引入权限、边界条件或算术安全问题。
