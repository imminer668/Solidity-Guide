# 30_PaymentSplit

## 对应教程

`0xF1/07_distribution/30_PaymentSplit.md`

## 项目概述

实现分账合约，包含原生实现和 OpenZeppelin 实现两种版本。分账合约允许将 ETH 按权重分给一组账户，遵循 Pull Payment 模式。

## 实现范围

1. PaymentSplit 原生实现 - 分账合约核心逻辑
2. PaymentSplitOZ OpenZeppelin 实现 - 继承自 PaymentSplit
3. receive 函数 - 接收 ETH 付款
4. release 函数 - 受益人领取份额
5. releasable 函数 - 计算可领取金额
6. pendingPayment 函数 - 计算应得份额
7. PayeeAdded/PaymentReleased/PaymentReceived 事件

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── PaymentSplit.sol
│   └── oz/
│       └── PaymentSplit.sol
├── test/
│   ├── raw/
│   │   └── PaymentSplit.t.sol
│   └── oz/
│       └── PaymentSplit.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示分账最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式