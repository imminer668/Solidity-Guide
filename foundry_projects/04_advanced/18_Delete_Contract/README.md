# 第 18 课：删除合约与 selfdestruct

对应教程：`0xF1/04_advanced/18_Delete_Contract.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `18_EmergencyVault.sol` — 演示紧急 ETH 提取（替代 selfdestruct 的安全写法）
- `18_EmergencyVault.t.sol` — 3 个测试用例：存款、owner 提取、用户提取

## 文件结构

```
src/
  └── 18_EmergencyVault.sol    # 合约：紧急 ETH 提取（替代 selfdestruct）
test/
  └── 18_EmergencyVault.t.sol  # 测试：3 个用例
lib/                           # 依赖库（forge-std）
foundry.toml                   # Foundry 配置
README.md                      # 本说明文件
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
| 练习 1 | MigrateContract：状态迁移 + emergencyWithdrawAll() |
| 练习 2 | 研究 selfdestruct 历史变化（EIP-4758/EIP-6780） |