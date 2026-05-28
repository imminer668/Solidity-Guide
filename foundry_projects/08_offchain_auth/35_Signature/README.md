# 35_Signature

## 对应教程

`0xF1/08_offchain_auth/35_Signature.md`

## 项目概述

实现 ECDSA 签名验证合约，包含原生实现和 OpenZeppelin 实现两种版本。利用 ECDSA 签名验证发放 NFT 白名单。

## 实现范围

1. ERC721 原生最小实现 - 简单的 ERC721 代币
2. ECDSA 库 - 签名创建和验证
3. SignatureNFT 原生实现 - 签名验证白名单
4. SignatureNFTOZ OpenZeppelin 实现 - 使用 OZ ECDSA 库
5. mint 函数 - 验证签名后铸造 NFT
6. getMessageHash 函数 - 打包消息
7. verify 函数 - ECDSA 验证
8. toEthSignedMessageHash - 以太坊签名消息格式
9. recoverSigner - 从签名恢复签名者地址

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── ERC721.sol
│   │   ├── ECDSA.sol
│   │   └── SignatureNFT.sol
│   └── oz/
│       └── SignatureNFT.sol
├── test/
│   ├── raw/
│   │   └── Signature.t.sol
│   └── oz/
│       └── Signature.t.sol
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
- `ECDSA` - OpenZeppelin ECDSA 签名验证库

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示签名验证最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式