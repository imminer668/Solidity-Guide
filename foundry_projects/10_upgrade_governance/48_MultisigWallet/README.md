# 48. MultisigWallet - 多签钱包

## 对应原始课程
`0xF1/10_upgrade_governance/48_MultisigWallet.md`

## 项目概述

本项目实现多签钱包合约，交易需要多个私钥持有者签名授权后才能执行。

## 实现范围

### raw 实现
- `src/raw/MultisigWallet.sol` - 多签钱包合约

### oz 实现
- `src/oz/MultisigWallet.sol` - OZ 实现（占位符）

## 文件结构

```
25_MultisigWallet/
├── src/
│   ├── raw/
│   │   └── MultisigWallet.sol   # 原生多签实现
│   └── oz/
│       └── MultisigWallet.sol   # OZ 实现（占位符）
├── test/
│   ├── raw/                     # 原生测试
│   └── oz/                      # OZ 测试
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### 多签钱包原理
- 多个多签人共同管理钱包
- 每笔交易需要达到门槛（threshold）数量的签名才可执行
- 防止单点故障和恶意操作

### 签名验证
- 使用 `ecrecover` 验证签名者身份
- 签名通过 `checkSignatures` 验证有效性

## OpenZeppelin 组件
无（待补充）

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
| 测试数 | 1 passed |