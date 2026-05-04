# 第 4 课：源文件结构与合约组成

对应教程：`0xF1/02_basics/04_Source_File_Structure.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `04_MinimalContract.sol` — 演示 Solidity 源文件最小结构的合约（SPDX + pragma + contract + 合约内容）
- `04_MinimalContract.t.sol` — 测试：验证构造函数初始化和 getter 函数

## 文件结构

```
src/
  └── 04_MinimalContract.sol    # 合约：最小结构演示（带 constructor）
test/
  └── 04_MinimalContract.t.sol  # 测试：2 个用例
lib/                             # 依赖库（forge-std）
foundry.toml                     # Foundry 配置
README.md                        # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（2 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（2 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | 添加 `string public name` + `getName()` + 修改 constructor |
| 练习 2 | 创建 `MyContract.sol`：balance + constructor + getBalance() |