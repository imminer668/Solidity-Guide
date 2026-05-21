# 27_WETH

## 对应教程

`0xF1/06_standards/27_WETH.md`

## 项目概述

实现 WETH (Wrapped ETH) 代币标准，包含原生实现和 OpenZeppelin 实现两种版本。本项目展示了如何将原生 ETH 封装为符合 ERC20 标准的 WETH，以及存款、取款、回调函数等核心功能。

## 实现范围

1. IERC20 接口 - ERC20 标准接口
2. WETH 原生最小实现 - 自定义 WETH 实现
3. WETH OpenZeppelin 实现 - 继承 ERC20 的 WETH
4. 存款功能 (deposit) - 将 ETH 存入合约，获得等量 WETH
5. 取款功能 (withdraw) - 销毁 WETH，取回等量 ETH
6. 回调函数 (fallback/receive) - 自动存款
7. Deposit/Withdraw 事件

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol
│   │   └── WETH.sol
│   └── oz/
│       └── WETH.sol
├── test/
│   ├── raw/
│   │   └── WETH.t.sol
│   └── oz/
│       └── WETH.t.sol
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

## OpenZeppelin 组件

- `ERC20` - OpenZeppelin ERC20 标准实现

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 WETH 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 原生实现 vs OpenZeppelin 实现区别

| 方面 | 原生实现 | OpenZeppelin 实现 |
|------|---------|------------------|
| 接口实现 | 手动实现 IERC20 | 继承 ERC20 基类 |
| decimals | 手动设置 18 | 继承自 ERC20 |
| 适用场景 | 学习原理 | 生产环境 |