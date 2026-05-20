# 25_ERC721

## 对应教程

`0xF1/06_standards/25_ERC721.md`

## 项目概述

实现 ERC721 非同质化代币（NFT）标准，包含原生实现和 OpenZeppelin 实现两种版本。本项目展示了 ERC721 接口定义、ownerOf/balanceOf/transfer/approve 等核心函数，以及 safeTransfer 和元数据扩展。

## 实现范围

1. IERC165 接口 - supportsInterface 检查
2. IERC721 接口 - 核心 NFT 函数和事件
3. IERC721Receiver 接口 - 安全转账接收检查
4. IERC721Metadata 接口 - name/symbol/tokenURI
5. ERC721 原生最小实现
6. ERC721 OpenZeppelin 实现
7. 铸造功能 (mint)
8. 销毁功能 (burn)
9. tokenURI 元数据查询

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC165.sol
│   │   ├── IERC721.sol
│   │   ├── IERC721Receiver.sol
│   │   ├── IERC721Metadata.sol
│   │   ├── String.sol
│   │   └── ERC721.sol
│   └── oz/
│       └── NFTToken.sol
├── test/
│   ├── raw/
│   │   └── ERC721.t.sol
│   └── oz/
│       └── NFTToken.t.sol
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

- `ERC721` - OpenZeppelin NFT 标准实现
- `Strings` - OpenZeppelin 字符串工具库

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 ERC721 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 原生实现 vs OpenZeppelin 实现区别

| 方面 | 原生实现 | OpenZeppelin 实现 |
|------|---------|------------------|
| 接口实现 | 手动实现全部接口 | 继承 ERC721 基类 |
| 安全检查 | 手动检查 | 内置 SafeTransfer 检查 |
| 元数据 | 需要手动实现 tokenURI | 可重写 _baseURI |
| 适用场景 | 学习原理 | 生产环境 |