# 29_Airdrop

## 对应教程

`0xF1/07_distribution/29_Airdrop.md`

## 项目概述

实现 ERC20 代币空投合约,包含 **push 批量模式**(正文) 和 **pull Merkle 模式**(扩展章节) 两套方案,以及原生 / OpenZeppelin 两种实现风格。

## 实现范围

### push 批量模式(正文)
1. IERC20 接口 - ERC20 标准接口
2. ERC20 原生最小实现 - 简单的 ERC20 代币
3. Airdrop 原生实现 - 批量转账 ERC20 代币
4. AirdropOZ OpenZeppelin 实现 - 使用 ERC20 实例批量转账
5. multiTransferToken - 批量转账 ERC20 代币
6. multiTransferETH - 批量转账 ETH
7. getSum - 数组求和函数
8. failTransferList - 追踪失败的转账

### pull Merkle 模式(扩展章节)
9. MerkleAirdrop - 用 OZ MerkleProof 实现的 pull 模式空投
10. 4 叶子 Merkle Tree 构造 + 验 proof 测试

## 文件结构

```
.
├── src/
│   ├── raw/
│   │   ├── IERC20.sol
│   │   ├── ERC20.sol
│   │   ├── Airdrop.sol          # push 批量模式
│   │   └── MerkleAirdrop.sol    # pull Merkle 模式(扩展)
│   └── oz/
│       ├── ERC20Minter.sol
│       └── Airdrop.sol
├── test/
│   ├── raw/
│   │   ├── Airdrop.t.sol        # push 测试(4 个)
│   │   └── MerkleAirdrop.t.sol  # pull 测试(5 个)
│   └── oz/
│       └── Airdrop.t.sol        # oz push 测试(2 个)
├── foundry.toml
├── remappings.txt
└── README.md
```

## 支持命令

| 命令 | 说明 |
|------|------|
| `forge build` | 编译合约 |
| `forge test` | 运行测试 |
| `forge test --match-path "test/raw/MerkleAirdrop.t.sol" -vv` | 仅跑 Merkle pull 模式测试 |

## 验收结果

- [x] `forge build` 通过
- [x] `forge test` 通过(11 个测试:4 raw push + 2 oz push + 5 raw pull)

## OpenZeppelin 组件

- `ERC20` - OpenZeppelin ERC20 标准实现
- `MerkleProof` - OpenZeppelin 验 Merkle proof 库(pull 模式核心)

## 双实现说明

- [x] 提供 `src/raw/` 原生实现 - 展示空投最小实现原理
- [x] 提供 `src/oz/` OpenZeppelin 实现 - 展示工业级实现方式

## push vs pull 模式对比

| 维度 | push 批量(正文) | pull Merkle(扩展) |
|------|----------------|-------------------|
| 白名单大小 | 几千人上限 | 几十万人 |
| 项目方 gas | 一次循环(可能 30M+) | 一次 deposit |
| 用户 gas | 0 | 自己付 claim gas |
| 失败处理 | failList + 提款 | 不存在"失败" |
| 链上数据 | 完整白名单 calldata | 只存 bytes32 root |
| 适用 | 小型空投 | 大型空投(UNI/OP/ARB/ENS) |