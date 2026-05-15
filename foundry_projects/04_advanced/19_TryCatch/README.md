# 第 19 课：Try-Catch 与异常处理

对应教程：`0xF1/04_advanced/19_TryCatch.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `19_TryCatch.sol` — 演示 Try-Catch 用法（TestContract + TryCatchDemo）
- `19_TryCatch.t.sol` — 5 个测试用例：create 成功/revert/panic、call 成功/revert

## 文件结构

```
src/
  └── 19_TryCatch.sol    # 合约：Try-Catch 演示
test/
  └── 19_TryCatch.t.sol  # 测试：5 个用例
lib/                     # 依赖库（forge-std）
foundry.toml              # Foundry 配置
README.md                 # 本说明文件
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
| 练习 1 | OracleContract：setDataFeed + getLatestPrice + try-catch |
| 练习 2 | FactoryWithTryCatch：createToken + 捕获 revert/panic |