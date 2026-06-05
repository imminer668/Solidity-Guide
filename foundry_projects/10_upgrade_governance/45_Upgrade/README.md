# 45. Upgrade - 可升级合约

## 对应原始课程
`0xF1/10_upgrade_governance/45_Upgrade.md`

## 项目概述

本项目实现简单的可升级合约模式，管理员可以通过升级函数更改逻辑合约地址。

## 实现范围

### raw 实现
- `src/raw/SimpleUpgrade.sol` - 代理合约
- `src/raw/Logic1.sol` - 旧逻辑合约
- `src/raw/Logic2.sol` - 新逻辑合约

### oz 实现
- `src/oz/SimpleUpgrade.sol` - **占位符**（未接入真实 OZ 依赖）
- `test/oz/` - **不存在**（oz 测试待补充）

## 文件结构

```
22_Upgrade/
├── src/
│   ├── raw/
│   │   ├── SimpleUpgrade.sol   # 原生代理实现
│   │   ├── Logic1.sol          # 旧逻辑合约
│   │   └── Logic2.sol          # 新逻辑合约
│   └── oz/
│       └── SimpleUpgrade.sol   # OZ 实现（占位符）
├── test/
│   ├── raw/                    # 原生测试 ✓
│   └── oz/                    # 不存在
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### 可升级合约原理
- 代理合约存储逻辑合约地址
- 用户调用通过 fallback 委托给逻辑合约
- 管理员可升级逻辑合约地址实现功能更新

### 插槽冲突
代理合约和逻辑合约必须保持相同的状态变量布局，防止存储槽冲突。

## OpenZeppelin 组件（oz 占位符）
- `TransparentUpgradeableProxy` - 如需真实 OZ 实现需安装 `openzeppelin-contracts-upgradeable`

## 额外依赖
- oz 占位符：需安装 `openzeppelin-contracts-upgradeable`
- raw 实现：无需额外依赖

## 安装 oz 依赖

```bash
forge install openzeppelin/openzeppelin-contracts-upgradeable@v5.2.0
```

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
| 测试数 | 6 passed |

## oz 实现说明

当前 `src/oz/` 为占位符状态，`test/oz/` 不存在。如需真实 OpenZeppelin 可升级代理实现，需：
1. 安装 `openzeppelin-contracts-upgradeable`
2. 在 `remappings.txt` 添加映射
3. 实现继承 `TransparentUpgradeableProxy` 的真实代理合约
4. 补充 `test/oz/` 测试文件