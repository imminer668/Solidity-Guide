# 38_MultiCall

## 对应教程

`0xF1/08_offchain_auth/38_MultiCall.md`

## 项目概述

实现 MultiCall 多重调用合约，支持在一次交易中执行多个函数调用。MultiCall 能将多个交易合并成一次交易中的多个调用，从而节省 gas，并保持原子性。

## 实现范围

1. MultiCall 原生实现 - 多重调用核心功能
2. MultiCallOZ OpenZeppelin 实现 - 继承自原生实现
3. multicall 函数 - 执行多个调用并处理失败
4. Call 和 Result 结构体 - 多重调用数据结构

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── MultiCall.sol
│   └── oz/
│       └── MultiCallOZ.sol
├── test/
│   ├── raw/
│   │   └── MultiCall.t.sol
│   └── oz/
│       └── MultiCall.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示 MultiCall 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式