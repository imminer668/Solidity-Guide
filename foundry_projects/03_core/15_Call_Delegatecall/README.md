# 第 15 课：合约调用：Call 与 Delegatecall

对应教程：`0xF1/03_core/15_Call_Delegatecall.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `15_CallDemo.sol` — 演示 call 和 delegatecall 的区别（LogicContract + ProxyContract）
- `15_CallDemo.t.sol` — 6 个测试用例：验证 call 不修改 caller storage、delegatecall 修改 caller storage

## 文件结构

```
src/
  └── 15_CallDemo.sol    # 合约：LogicContract + ProxyContract
test/
  └── 15_CallDemo.t.sol  # 测试：6 个用例
lib/                      # 依赖库（forge-std）
foundry.toml              # Foundry 配置
README.md                 # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（6 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（6 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | 验证 call 和 delegatecall 行为差异：TargetA/B + CallerContract |
| 练习 2 | CounterLogic + CounterProxy 计数器代理 |