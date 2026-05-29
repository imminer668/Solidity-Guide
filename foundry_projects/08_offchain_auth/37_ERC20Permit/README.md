# 37. ERC20Permit - ERC20 无approve转账

## 对应原始课程
`0xF1/08_offchain_auth/37_ERC20Permit.md`

## 项目概述

本项目实现 ERC20 Permit 扩展，允许 Token 持有者通过签名授权他人使用代币，无需先发起 approve 交易。

## 实现范围

### raw 实现
- `src/raw/ERC20Permit.sol` - 原生 ERC20Permit 实现
- `src/raw/ECDSA.sol` - ECDSA 签名验证

### oz 实现
- `src/oz/ERC20Permit.sol` - OpenZeppelin ERC20Permit 实现（继承自原生实现）

## 文件结构

```
14_ERC20Permit/
├── src/
│   ├── raw/
│   │   ├── ERC20Permit.sol    # 原生实现
│   │   └── ECDSA.sol          # ECDSA 签名工具
│   └── oz/
│       └── ERC20Permit.sol    # OZ 实现
├── test/
│   ├── raw/                   # 原生测试
│   └── oz/                    # OZ 测试
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### Permit 机制
传统 ERC20 需要两步操作才能完成授权转账：
1. approve - 授权
2. transferFrom - 转账

Permit 允许在一签名中直接授权并转账（EIP-2612）：
- owner 签名授权 spender 使用 value 数量的代币
- 无需先发送 approve 交易，节省 Gas

### DOMAIN_SEPARATOR
用于防止签名重放攻击，包含：
- 链 ID
- 合约地址
- Name/Version

## OpenZeppelin 组件
- `ERC20Permit` - OpenZeppelin 的 ERC20Permit 实现
- `ECDSA` - 签名验证工具

## 额外依赖
无

## 支持命令

```bash
forge build   # 编译
forge test    # 测试
```

## 验收结果

| 检查项 | 结果 |
|--------|------|
| forge build | ✓ |
| forge test | ✓ |
| 测试数 | 3 passed |