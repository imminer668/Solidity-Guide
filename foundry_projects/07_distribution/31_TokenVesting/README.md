# 31_TokenVesting

## 对应教程

`0xF1/07_distribution/31_TokenVesting.md`

## 项目概述

实现线性释放合约，包含原生实现和 OpenZeppelin 实现两种版本。受益人在归属期内匀速释放代币。

## 实现范围

1. IERC20 接口 - ERC20 标准接口
2. ERC20 原生最小实现 - 简单的 ERC20 代币
3. TokenVesting 原生实现 - 线性释放逻辑
4. TokenVestingOZ OpenZeppelin 实现 - 使用 IERC20 接口
5. release 函数 - 提取已释放代币
6. vestedAmount 函数 - 计算已释放数量
7. ERC20Released 事件

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol
│   │   ├── ERC20.sol
│   │   └── TokenVesting.sol
│   └── oz/
│       ├── ERC20Minter.sol
│       └── TokenVesting.sol
├── test/
│   ├── raw/
│   │   └── TokenVesting.t.sol
│   └── oz/
│       └── TokenVesting.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示线性释放最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式