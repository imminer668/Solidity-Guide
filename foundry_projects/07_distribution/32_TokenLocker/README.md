# 32_TokenLocker

## 对应教程

`0xF1/07_distribution/32_TokenLocker.md`

## 项目概述

实现代币锁合约，包含原生实现和 OpenZeppelin 实现两种版本。在锁仓期满后将代币释放给受益人。

## 实现范围

1. IERC20 接口 - ERC20 标准接口
2. ERC20 原生最小实现 - 简单的 ERC20 代币
3. TokenLocker 原生实现 - 代币锁核心逻辑
4. TokenLockerOZ OpenZeppelin 实现 - 使用 IERC20 接口
5. release 函数 - 锁仓期满后提取代币
6. TokenLockStart/Release 事件

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol
│   │   ├── ERC20.sol
│   │   └── TokenLocker.sol
│   └── oz/
│       ├── ERC20Minter.sol
│       └── TokenLocker.sol
├── test/
│   ├── raw/
│   │   └── TokenLocker.t.sol
│   └── oz/
│       └── TokenLocker.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示代币锁最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式