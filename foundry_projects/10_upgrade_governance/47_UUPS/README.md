# 47. UUPS - 通用可升级代理标准

## 对应原始课程
`0xF1/10_upgrade_governance/47_UUPS.md`

## 项目概述

本项目实现 UUPS 代理模式，将升级函数放在逻辑合约中而非代理合约。

## 实现范围

### raw 实现
- `src/raw/UUPS.sol` - UUPS 代理合约
- `src/raw/UUPS1.sol` - 旧逻辑合约
- `src/raw/UUPS2.sol` - 新逻辑合约

### oz 实现
- `src/oz/UUPS.sol` - 继承 OpenZeppelin 的 `UUPSUpgradeable` + `Initializable`，提供 `UUPSLogicV1OZ` 与 `UUPSLogicV2OZ` 两个版本

## 文件结构

```
47_UUPS/
├── src/
│   ├── raw/
│   │   ├── UUPS.sol      # 原生 UUPS 实现
│   │   ├── UUPS1.sol     # 旧逻辑合约
│   │   └── UUPS2.sol     # 新逻辑合约
│   └── oz/
│       └── UUPS.sol      # OZ 实现（UUPSLogicV1OZ / UUPSLogicV2OZ）
├── test/
│   ├── raw/              # 原生测试 ✓
│   └── oz/               # OZ 测试 ✓
├── lib/                  # 依赖库（含 openzeppelin-contracts-upgradeable）
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### UUPS 原理
- 升级函数放在逻辑合约中
- 如果有其它函数与升级函数存在选择器冲突，编译时即报错
- 比透明代理更安全

### 与透明代理对比
- 透明代理：升级函数在代理合约，管理员可升级
- UUPS：升级函数在逻辑合约，编译期检查冲突

## OpenZeppelin 组件（oz 实现已落地）
- `UUPSUpgradeable` - 提供 `_authorizeUpgrade` 钩子与 ERC-1822 兼容入口
- `Initializable` - 取代构造函数，配合代理模式做一次性初始化

## 额外依赖
- oz 实现：依赖 `openzeppelin-contracts-upgradeable@v5.2.0`（已通过 git submodule 安装在 `lib/`）
- raw 实现：无需额外依赖

## 重新安装 oz 依赖（如缺失）

```bash
forge install openzeppelin/openzeppelin-contracts-upgradeable@v5.2.0
```

安装后确认 `lib/openzeppelin-contracts-upgradeable/` 目录存在，并在 `remappings.txt` 中有 `@openzeppelin/contracts-upgradeable/=lib/openzeppelin-contracts-upgradeable/contracts/`。

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
| 测试数 | 8 passed（raw 5 + oz 3） |

## oz 实现说明

`src/oz/UUPS.sol` 已经基于 OpenZeppelin 的可升级合约库实现，包含：

- `UUPSLogicV1OZ`：继承 `Initializable` + `UUPSUpgradeable`，通过 `initialize(address)` 完成初始化
- `UUPSLogicV2OZ`：升级后的逻辑合约
- 二者都 override 了 `_authorizeUpgrade`（示例代码中留空，生产环境应加上 owner / role 检查）

对应测试位于 `test/oz/UUPS.t.sol`，覆盖部署、初始化与升级三个用例。