# 49. Random - 链上随机数生成

## 对应原始课程
`0xF1/11_external_systems/49_Random.md`

## 项目概述

本项目演示 Solidity 中链上随机数生成的两种方法：
- **raw 实现**：教学演示，展示链上伪随机数的安全局限
- **oz 实现**：基于 Chainlink VRF v2 的可验证随机数方案

## 实现范围

### raw 实现
- `src/raw/SimpleRandom.sol` - 伪随机数生成合约（不安全方案，演示用）

### oz 实现（基于 Chainlink VRF v2）
- `src/oz/SimpleRandom.sol` - 消费 Chainlink VRF 随机数
- `src/oz/VRFConsumerBaseV2.sol` - 兼容 Chainlink 官方的 VRF 消费者基类
  - 自包含实现（不依赖外部 chainlink 仓库）
  - 接口与官方 VRFConsumerBaseV2 完全兼容
  - 生产环境可替换为官方库

## 文件结构

```
26_Random/
├── src/
│   ├── raw/
│   │   └── SimpleRandom.sol          # 原生实现（不安全演示）
│   └── oz/
│       ├── SimpleRandom.sol          # OZ 实现（VRF 消费者）
│       └── VRFConsumerBaseV2.sol     # VRF 消费者基类（精简）
├── test/
│   ├── raw/                          # 原生测试
│   └── oz/
│       ├── SimpleRandom.t.sol        # OZ 测试
│       └── VRFCoordinatorV2Mock.sol  # 本地 VRF 协调器 mock
├── lib/
│   ├── forge-std/
│   └── openzeppelin-contracts/
├── foundry.toml
├── remappings.txt
└── README.md
```

## 核心概念

### 链上伪随机数（raw 实现）
- 矿工/用户可操纵 `blockhash`、`block.timestamp`
- 攻击者可预测结果
- 知名项目（Meebits、Loots）因此类方案遭攻击

### Chainlink VRF（oz 实现）
工作流程：
1. 用户调用 `requestRandom()` 提交请求
2. 合约调用 `VRFCoordinator.requestRandomWords()`
3. Chainlink 预言机在链下生成可验证随机数
4. 预言机回调 `fulfillRandomWords()` 提供结果
5. 用户通过 `getRandomResult(requestId)` 获取

安全性：
- 预言机无法预知 `requestId` 之后的区块
- 链下生成 + 链上验证，矿工无法操纵
- 业界标准的可验证随机性方案

## OpenZeppelin 组件
- `Ownable` - 权限管理

## 额外依赖
- `openzeppelin-contracts` - OZ 标准库

## 测试说明

本项目使用自包含的 `VRFCoordinatorV2Mock` 模拟 Chainlink 协调器，无需真实预言机即可完整测试 VRF 流程：

- `setSeed(requestId, value)` - 预设随机数
- `fulfillRandomWords(requestId, consumer)` - 手动触发回调

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
| raw 测试 | 8 passed |
| oz 测试 | 14 passed |