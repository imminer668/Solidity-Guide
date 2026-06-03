# 41_ERC4626

## 对应教程

`0xF1/09_protocols/41_ERC4626.md`

## 项目概述

实现 ERC4626 代币化金库标准，支持将基础资产质押并换取金库份额代币。

## 实现范围

1. IERC4626 接口合约 - 定义 16 个函数和 2 个事件
2. ERC4626 原生实现 - 1:1 铸造金库份额
3. ERC4626 OZ wrapper - 继承自原生实现
4. deposit/mint - 存款和铸造函数
5. withdraw/redeem - 取款和赎回函数
6. convertToShares/convertToAssets - 会计转换函数
7. maxDeposit/maxMint/maxWithdraw/maxRedeem - 限额函数

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC4626.sol
│   │   └── ERC4626.sol
│   └── oz/
│       └── ERC4626.sol
├── test/
│   ├── raw/
│   │   └── ERC4626.t.sol
│   └── oz/
│       └── ERC4626.t.sol
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
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

- [x] 提供 `src/raw/` 原生实现 - 展示 ERC4626 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin wrapper - 继承自原生实现