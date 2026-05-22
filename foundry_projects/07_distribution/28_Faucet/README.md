# 28_Faucet

## 对应教程

`0xF1/07_distribution/28_Faucet.md`

## 项目概述

实现 ERC20 代币水龙头合约，包含原生实现和 OpenZeppelin 实现两种版本。用户可以通过水龙头合约领取一次免费代币。

## 实现范围

1. IERC20 接口 - ERC20 标准接口
2. ERC20 原生最小实现 - 简单的 ERC20 代币
3. Faucet 原生实现 - 使用 IERC20 接口申领代币
4. FaucetOZ OpenZeppelin 实现 - 使用 ERC20 实例申领代币
5. requestTokens 函数 - 每次领取 100 单位代币
6. 防重复领取机制 - mapping(address => bool)

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol
│   │   ├── ERC20.sol
│   │   └── Faucet.sol
│   └── oz/
│       └── Faucet.sol
├── test/
│   ├── raw/
│   │   └── Faucet.t.sol
│   └── oz/
│       └── Faucet.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示水龙头最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 原生实现 vs OpenZeppelin 实现区别

| 方面 | 原生实现 | OpenZeppelin 实现 |
|------|---------|------------------|
| erc20 接口 | 使用 IERC20 接口 | 直接使用 ERC20 实例 |
| 适用场景 | 学习原理 | 生产环境 |