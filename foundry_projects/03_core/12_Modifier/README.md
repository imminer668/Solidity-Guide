# 第 12 课：Modifier 与权限控制

对应教程：`0xF1/03_core/12_Modifier.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `12_Modifier.sol` — 演示 modifier（onlyOwner/onlyAdmin/whenNotPaused）和权限控制
- `12_Modifier.t.sol` — 5 个测试用例：owner/admin/stranger 权限、pause 功能

## 文件结构

```
src/
  └── 12_Modifier.sol    # 合约：modifier + 权限控制
test/
  └── 12_Modifier.t.sol  # 测试：5 个用例
lib/                     # 依赖库（forge-std）
foundry.toml             # Foundry 配置
README.md                # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（5 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（5 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | TimelockContract：lockedUntil mapping + onlyAfterLock modifier |
| 练习 2 | MultiSigWallet：owners array + onlyOwner modifier |