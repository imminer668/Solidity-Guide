# 46. TransparentProxy - 透明代理

## 对应原始课程
`0xF1/10_upgrade_governance/46_TransparentProxy.md`

## 项目概述

本项目实现透明代理模式，通过限制管理员调用逻辑合约来解决选择器冲突问题。

## 实现范围

### raw 实现
- `src/raw/TransparentProxy.sol` - 代理合约
- `src/raw/Logic1.sol` - 旧逻辑合约
- `src/raw/Logic2.sol` - 新逻辑合约

### oz 实现
- `src/oz/TransparentProxy.sol` - **占位符**（未接入真实 OZ 依赖）
- `test/oz/` - **不存在**（oz 测试待补充）

## 文件结构

```
23_TransparentProxy/
├── src/
│   ├── raw/
│   │   ├── TransparentProxy.sol   # 原生代理实现
│   │   ├── Logic1.sol             # 旧逻辑合约
│   │   └── Logic2.sol             # 新逻辑合约
│   └── oz/
│       └── TransparentProxy.sol    # OZ 实现（占位符）
├── test/
│   ├── raw/                       # 原生测试 ✓
│   └── oz/                        # 不存在
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### 透明代理原理
- **管理员变为工具人**：仅能调用代理合约的可升级函数对合约升级
- **其它用户**：不能调用可升级函数，但可以调用逻辑合约的函数
- 通过区分 msg.sender 解决选择器冲突

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
| 测试数 | 8 passed |

## oz 实现说明

当前 `src/oz/` 为占位符状态，`test/oz/` 不存在。如需真实 OpenZeppelin 透明代理实现，需：
1. 安装 `openzeppelin-contracts-upgradeable`
2. 在 `remappings.txt` 添加映射
3. 实现继承 `TransparentUpgradeableProxy` 的真实代理合约
4. 补充 `test/oz/` 测试文件