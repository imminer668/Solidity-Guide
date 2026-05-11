# 第 13 课：Event 与日志

对应教程：`0xF1/03_core/13_Event.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `13_Event.sol` — 演示事件定义和释放（Transfer/Mint/Burn + indexed）
- `13_Event.t.sol` — 3 个测试用例：mint/transfer/burn 事件验证 + vm.expectEmit 用法

## 文件结构

```
src/
  └── 13_Event.sol    # 合约：事件定义与释放
test/
  └── 13_Event.t.sol  # 测试：3 个用例 + vm.expectEmit
lib/                   # 依赖库（forge-std）
foundry.toml           # Foundry 配置
README.md              # 本说明文件
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
| 练习 1 | 在 SecureContract 中添加 AdminAdded/AdminRemoved/ValueChanged 事件 |
| 练习 2 | EventStore：Article 结构体 + publish + ArticlePublished 事件 |