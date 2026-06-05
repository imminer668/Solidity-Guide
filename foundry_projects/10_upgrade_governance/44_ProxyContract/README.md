# 44_ProxyContract

## 对应教程

`0xF1/10_upgrade_governance/44_ProxyContract.md`

## 项目概述

实现代理合约（Proxy Contract），展示将合约数据和逻辑分离的代理模式。代理合约通过 `delegatecall` 将函数调用委托给逻辑合约执行，实现可升级性和节省 gas。

## 实现范围

1. Proxy 代理合约 - 将调用委托给 Logic 合约
2. ProxyOZ OpenZeppelin 实现 - 继承自原生实现
3. Logic 逻辑合约 - 执行被委托的调用
4. Caller 调用者合约 - 通过 call 调用代理合约
5. fallback 函数 - 处理代理调用
6. 状态变量存储对齐 - 防止插槽冲突

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── Proxy.sol
│   └── oz/
│       └── Proxy.sol
├── test/
│   ├── raw/
│   │   └── Proxy.t.sol
│   └── oz/
│       └── Proxy.t.sol
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

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示 Proxy 最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式