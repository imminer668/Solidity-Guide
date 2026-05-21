# 26_ERC1155

## 对应教程

`0xF1/06_standards/26_ERC1155.md`

## 项目概述

实现 ERC1155 多代币标准，包含原生实现和 OpenZeppelin 实现两种版本。本项目展示了 ERC1155 接口定义、单币/批量转账、铸造、销毁等功能，以及 uri 元数据查询。

## 实现范围

1. IERC165 接口 - supportsInterface 检查
2. IERC1155 接口 - 核心多代币函数和事件
3. IERC1155Receiver 接口 - 安全转账接收检查
4. IERC1155MetadataURI 接口 - uri 元数据
5. ERC1155 原生最小实现
6. ERC1155 OpenZeppelin 实现
7. 单币铸造 (mint)
8. 批量铸造 (mintBatch)
9. 单币销毁 (burn)
10. uri 元数据查询

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC165.sol
│   │   ├── IERC1155.sol
│   │   ├── IERC1155Receiver.sol
│   │   ├── IERC1155MetadataURI.sol
│   │   ├── String.sol
│   │   └── ERC1155.sol
│   └── oz/
│       └── MultiToken.sol
├── test/
│   ├── raw/
│   │   └── ERC1155.t.sol
│   └── oz/
│       └── MultiToken.t.sol
├── foundry.toml
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

- `ERC1155` - OpenZeppelin 多代币标准实现

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 ERC1155 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 原生实现 vs OpenZeppelin 实现区别

| 方面 | 原生实现 | OpenZeppelin 实现 |
|------|---------|------------------|
| 接口实现 | 手动实现全部接口 | 继承 ERC1155 基类 |
| 安全检查 | 手动检查 | 内置 SafeTransfer 检查 |
| uri | 需要手动实现 | 通过构造函数传入 |
| 适用场景 | 学习原理 | 生产环境 |