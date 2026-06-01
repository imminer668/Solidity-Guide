# 39_DutchAuction

## 对应教程

`0xF1/09_protocols/39_DutchAuction.md`

## 项目概述

实现 DutchAuction 荷兰拍卖合约，支持以递减价格发售 NFT。荷兰拍卖的特点是价格由高到低递减，直到买家应价成交。

## 实现范围

1. DutchAuction 原生实现 - 荷兰拍卖核心功能
2. DutchAuctionOZ OpenZeppelin 实现 - 继承自原生实现
3. ERC721 简化实现 - NFT 标准
4. getAuctionPrice 函数 - 获取实时拍卖价格
5. auctionMint 函数 - 参与拍卖并铸造 NFT
6. withdrawMoney 函数 - 项目方提取 ETH

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── DutchAuction.sol
│   │   └── ERC721.sol
│   └── oz/
│       └── DutchAuction.sol
├── test/
│   ├── raw/
│   │   └── DutchAuction.t.sol
│   └── oz/
│       └── DutchAuction.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示 DutchAuction 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式