# 50. CrossChainBridge - 跨链桥

## 对应原始课程
`0xF1/11_external_systems/50_CrossChainBridge.md`

## 项目概述

本项目实现简化的跨链桥合约，演示 lock/mint 和 stake/unlock 模式。

## 实现范围

### raw 实现
- `src/raw/SimpleBridge.sol` - 跨链桥合约

### oz 实现
- `src/oz/SimpleBridge.sol` - OZ 实现（占位符）

## 文件结构

```
27_CrossChainBridge/
├── src/
│   ├── raw/
│   │   └── SimpleBridge.sol   # 原生实现
│   └── oz/
│       └── SimpleBridge.sol   # OZ 实现（占位符）
├── test/
│   ├── raw/                   # 原生测试
│   └── oz/                    # OZ 测试
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### Burn/Mint 模式
- 用户在源链燃烧代币
- 桥接操作员在目标链铸造代币
- 总供应量跨链保持一致

### Stake/Unlock 模式
- 用户在源链锁定代币
- 桥接操作员在目标链解锁代币
- 需要目标链有流动性

## OpenZeppelin 组件
无

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