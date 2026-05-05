# 第 6 课：函数：定义、返回值、可见性

对应教程：`0xF1/02_basics/06_Function.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `06_Function.sol` — 演示函数定义、返回值、可见性（external/pure/constructor/internal）
- `06_Function.t.sol` — 5 个测试用例：验证初始值、setValue、getValue、calculate、双返回值

## 文件结构

```
src/
  └── 06_Function.sol    # 合约：函数可见性、返回值、内部函数调用
test/
  └── 06_Function.t.sol  # 测试：5 个用例
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
| 练习 1 | BankContract：owner + deposit/withdraw/getBalance |
| 练习 2 | average(a,b,c) 纯函数，命名返回值写法 |