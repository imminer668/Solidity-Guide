# 第 9 课：映射类型 mapping

对应教程：`0xF1/02_basics/09_Mapping.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `09_Mapping.sol` — 演示 mapping 用法（address=>uint256 余额、address=>bool 管理员、嵌套）、modifier、deposit/withdraw
- `09_Mapping.t.sol` — 4 个测试用例：初始余额、存款、取款、默认值

## 文件结构

```
src/
  └── 09_Mapping.sol    # 合约：mapping + modifier + 存取款
test/
  └── 09_Mapping.t.sol  # 测试：4 个用例
lib/                     # 依赖库（forge-std）
foundry.toml             # Foundry 配置
README.md                # 本说明文件
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
| 练习 1 | VoterRegistry：hasVoted + voteCounts + candidates + vote() |
| 练习 2 | StudentRecord：Score 结构体 + scores mapping + register/setScore/getTotalScore |