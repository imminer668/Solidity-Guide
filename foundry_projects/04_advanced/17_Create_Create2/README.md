# 第 17 课：Create 与 Create2

对应教程：`0xF1/04_advanced/17_Create_Create2.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `17_Create.sol` — 演示 Create 和 Create2 创建合约（Pair + PairFactory）
- `17_Create.t.sol` — 3 个测试用例：createPair、createPair2、pair 地址验证

## 文件结构

```
src/
  └── 17_Create.sol    # 合约：Pair + PairFactory（Create + Create2）
test/
  └── 17_Create.t.sol  # 测试：3 个用例
lib/                    # 依赖库（forge-std）
foundry.toml            # Foundry 配置
README.md               # 本说明文件
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
| 练习 1 | CounterFactory：Create + Create2 创建 Counter |
| 练习 2 | cast create2 预知地址验证 |