# 33_Timelock

## 对应教程

`0xF1/07_distribution/33_Timelock.md`

## 项目概述

实现时间锁合约，包含原生实现和 OpenZeppelin 实现两种版本。时间锁将交易锁定一段时间后才执行，防止 rug pull 和黑客攻击。

## 实现范围

1. Timelock 原生实现 - 时间锁核心逻辑
2. TimelockOZ OpenZeppelin 实现 - 继承自 Timelock
3. queueTransaction - 创建交易并添加到时间锁队列
4. executeTransaction - 执行已解锁的交易
5. cancelTransaction - 取消队列中的交易
6. changeAdmin - 修改管理员地址（仅时间锁合约可调用）
7. getTxHash - 计算交易唯一标识符
8. onlyOwner / onlyTimelock 修饰器

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   └── Timelock.sol
│   └── oz/
│       └── Timelock.sol
├── test/
│   ├── raw/
│   │   └── Timelock.t.sol
│   └── oz/
│       └── Timelock.t.sol
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

- [x] 提供 `src/raw/` 原生实现 - 展示时间锁最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式