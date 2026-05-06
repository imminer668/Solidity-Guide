# 第 7 课：数据存储位置

对应教程：`0xF1/02_basics/07_Data_Location.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `07_DataLocation.sol` — 演示 storage/memory/calldata 三种数据位置
- `07_DataLocation.t.sol` — 2 个测试用例：验证 calldata sum 和 memory double

## 文件结构

```
src/
  └── 07_DataLocation.sol    # 合约：storage 状态变量 + calldata/memory 参数
test/
  └── 07_DataLocation.t.sol  # 测试：2 个用例
lib/                         # 依赖库（forge-std）
foundry.toml                 # Foundry 配置
README.md                    # 本说明文件
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
| 练习 1 | DataLocationPractice：storageArr + sumArr() + doubleArr() |
| 练习 2 | mergeString(a, b) 返回拼接字符串 |