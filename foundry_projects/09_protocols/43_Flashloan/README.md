# 43_Flashloan

## 对应教程

`0xF1/09_protocols/43_Flashloan.md`

## 项目概述

实现闪电贷（Flashloan）合约，展示 DeFi 中无需抵押即可借用大量资金的模式。闪电贷利用以太坊交易的原子性：要么完全执行，要么完全不执行。

## 实现范围

1. SimpleFlashloan 原生实现 - 演示闪电贷核心模式
2. SimpleFlashloanOZ OpenZeppelin 实现 - 继承自原生实现
3. FlashloanReceiver 接收者合约 - 处理闪电贷回调
4. MockERC20 测试用代币
5. flashloan 函数 - 借出代币并触发回调
6. onFlashloan 回调函数 - 执行闪电贷逻辑

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── Flashloan.sol
│   └── oz/
│       └── Flashloan.sol
├── test/
│   ├── raw/
│   │   └── Flashloan.t.sol
│   └── oz/
│       └── Flashloan.t.sol
├── foundry.toml
├── remappings.txt
└── README.md
```

## 支持命令

| 命令 | 说明 |
|------|------|
| `forge build` | 编译合约 |
| `forge test` | 运行测试 |

## 验收结果

- [x] `forge build` 通过
- [x] `forge test` 通过

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示闪电贷最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 外部依赖说明

本项目使用本地 Mock 实现展示闪电贷核心模式。实际生产中推荐使用：
- Uniswap V2/V3 闪电贷（需要 fork 测试）
- AAVE V3 闪电贷（需要 fork 测试）
