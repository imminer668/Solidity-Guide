# 24_ERC20

## 对应教程

`0xF1/06_standards/24_ERC20.md`

## 项目概述

实现 ERC20 代币标准，包含原生实现和 OpenZeppelin 实现两种版本。本项目展示了 ERC20 接口定义、核心函数实现（transfer/approve/transferFrom）、状态变量（balanceOf/allowance/totalSupply）以及 mint/burn 辅助功能。

## 实现范围

1. IERC20 接口定义 - 6 个核心函数 + 2 个事件
2. ERC20 原生最小实现
3. ERC20 OpenZeppelin 实现
4. 转账功能 (transfer)
5. 授权功能 (approve)
6. 授权转账功能 (transferFrom)
7. 铸造功能 (mint)
8. 销毁功能 (burn)

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol      # ERC20 接口定义
│   │   └── ERC20.sol       # 原生实现
│   └── oz/
│       └── ERC20Token.sol  # OpenZeppelin 实现
├── test/
│   ├── raw/
│   │   └── ERC20.t.sol     # 原生实现测试
│   └── oz/
│       └── ERC20Token.t.sol # OZ 实现测试
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

- `ERC20` - 使用 OpenZeppelin 的 ERC20 基类实现
- `ERC20.decimals()` - 重写以支持自定义精度

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 ERC20 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## 原生实现 vs OpenZeppelin 实现区别

| 方面 | 原生实现 | OpenZeppelin 实现 |
|------|---------|------------------|
| 状态变量 | 手动定义 balanceOf/allowance/totalSupply | 继承自 ERC20 基类 |
| 精度 | 固定 18 位 | 可自定义（通过 decimals 重写） |
| 安全 | 无溢出检查（v0.8+ 自动检查） | 使用 SafeERC20 等安全工具 |
| 适用场景 | 学习原理 | 生产环境 |