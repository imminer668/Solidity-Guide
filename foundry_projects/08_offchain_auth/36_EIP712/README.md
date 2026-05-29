# 36_EIP712

## 对应教程

`0xF1/08_offchain_auth/36_EIP712.md`

## 项目概述

实现 EIP712 类型化数据签名合约，包含原生实现和 OpenZeppelin 实现两种版本。EIP712 是一种更先进、安全的签名方法，钱包会展示签名消息的原始数据。

## 实现范围

1. EIP712Storage 原生实现 - 类型化数据签名验证
2. EIP712StorageOZ OpenZeppelin 实现 - 继承自原生实现
3. ECDSA 库 - 签名恢复
4. permitStore 函数 - 验证 EIP712 签名并存储值
5. retrieve 函数 - 获取存储的值
6. DOMAIN_SEPARATOR - 域分隔符

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── ECDSA.sol
│   │   └── EIP712Storage.sol
│   └── oz/
│       └── EIP712Storage.sol
├── test/
│   ├── raw/
│   │   └── EIP712Storage.t.sol
│   └── oz/
│       └── EIP712Storage.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示 EIP712 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式