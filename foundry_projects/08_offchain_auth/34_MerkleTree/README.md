# 34_MerkleTree

## 对应教程

`0xF1/08_offchain_auth/34_MerkleTree.md`

## 项目概述

实现 MerkleTree 合约，包含原生实现和 OpenZeppelin 实现两种版本。利用 Merkle 树验证白名单并铸造 NFT。

## 实现范围

1. MerkleProof 库 - Merkle 树证明验证
2. ERC721 原生最小实现 - 简单的 ERC721 代币
3. MerkleTree 原生实现 - 白名单验证和 NFT 铸造
4. MerkleTreeOZ OpenZeppelin 实现 - 使用 OZ 库
5. mint 函数 - 验证 Merkle 证明后铸造 NFT
6. _leaf 函数 - 计算地址的叶子哈希
7. _verify 函数 - 验证 Merkle 证明

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── MerkleProof.sol
│   │   ├── ERC721.sol
│   │   └── MerkleTree.sol
│   └── oz/
│       └── MerkleTree.sol
├── test/
│   ├── raw/
│   │   └── MerkleTree.t.sol
│   └── oz/
│       └── MerkleTree.t.sol
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

- `ERC721` - OpenZeppelin ERC721 标准实现
- `MerkleProof` - OpenZeppelin Merkle 证明验证库

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 MerkleTree 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式