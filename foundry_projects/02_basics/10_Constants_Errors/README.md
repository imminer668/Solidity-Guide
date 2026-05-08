# 第 10 课：常量与错误处理基础

对应教程：`0xF1/02_basics/10_Constants_Errors.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `10_Constants_Errors.sol` — 演示 constant/immutable、自定义 error（InsufficientBalance/Unauthorized/ZeroAmount）、require/revert、receive ETH
- `10_Constants_Errors.t.sol` — 3 个测试用例：存款、取款、ZeroAmount revert

## 文件结构

```
src/
  └── 10_Constants_Errors.sol    # 合约：constant/immutable + 自定义 error + 存取值
test/
  └── 10_Constants_Errors.t.sol  # 测试：3 个用例
lib/                               # 依赖库（forge-std）
foundry.toml                       # Foundry 配置
README.md                          # 本说明文件
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
| 练习 1 | VendingMachine：ITEM_PRICE + owner + inventory + buy() |
| 练习 2 | 添加自定义 error：NotEnoughInventory/IncorrectPayment/Unauthorized |