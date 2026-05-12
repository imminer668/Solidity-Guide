# 第 14 课：ETH 收发与 fallback

对应教程：`0xF1/03_core/14_Eth_Fallback.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `14_EthWallet.sol` — 演示 receive/fallback 接收 ETH + call 发送 ETH + onlyOwner 权限
- `14_EthWallet.t.sol` — 3 个测试用例：收 ETH、取款、权限控制

## 文件结构

```
src/
  └── 14_EthWallet.sol    # 合约：receive/fallback + call 转账 + 权限
test/
  └── 14_EthWallet.t.sol  # 测试：3 个用例
lib/                       # 依赖库（forge-std）
foundry.toml                # Foundry 配置
README.md                   # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（3 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（3 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | SplitWallet：三人分账（50%/25%/25%）+ getBalances() |
| 练习 2 | 添加 withdrawMyShare() + Withdrawal 事件 |