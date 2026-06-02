# 40_NFTSwap

## 对应教程

`0xF1/09_protocols/40_NFTSwap.md`

## 项目概述

实现 NFTSwap 去中心化 NFT 交易所合约，支持挂单/撤单/修改价格/购买功能。

## 设计逻辑

- 卖家：出售NFT的一方，可以挂单`list`、撤单`revoke`、修改价格`update`。
- 买家：购买NFT的一方，可以购买`purchase`。
- 订单：卖家发布的NFT链上订单，其中包含挂单价格`price`和持有人`owner`信息。

## 实现范围

1. NFTSwap 原生实现 - NFT交易所核心功能
2. NFTSwapOZ OpenZeppelin 实现 - 继承自原生实现
3. Order 结构体 - 包含owner和price
4. nftList 映射 - 追踪NFT订单
5. IERC721Receiver 实现 - 安全接收NFT

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── NFTSwap.sol
│   └── oz/
│       └── NFTSwap.sol
├── test/
│   ├── raw/
│   │   └── NFTSwap.t.sol
│   └── oz/
│       └── NFTSwap.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示 NFTSwap 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式