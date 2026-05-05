# 第 5 课：值类型与默认值

对应教程：`0xF1/02_basics/05_Value_Types.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `05_ValueTypes.sol` — 演示各类值类型：bool、int/uint、address、bytes32、enum 及默认值
- `05_ValueTypes.t.sol` — 4 个测试用例：验证默认值、flag、status 值

## 文件结构

```
src/
  └── 05_ValueTypes.sol    # 合约：值类型演示（bool/int/uint/address/bytes32/enum）
test/
  └── 05_ValueTypes.t.sol  # 测试：4 个用例（默认值、flag、status）
lib/                       # 依赖库（forge-std）
foundry.toml               # Foundry 配置
README.md                  # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（4 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（4 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | TokenContract：name/symbol/totalSupply/minter + mint() |
| 练习 2 | Grade 枚举 + getGradeScore() + 5 个等级测试 |