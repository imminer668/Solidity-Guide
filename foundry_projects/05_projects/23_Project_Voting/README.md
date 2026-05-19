# 第 23 课：综合练习 3 — Voting 项目

对应教程：`0xF1/05_projects/23_Project_Voting.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `src/Voting.sol` — Voting 合约（候选人管理/投票/onlyChairperson）
- `test/Voting.t.sol` — 8 个测试用例

## 文件结构

```
src/
  └── Voting.sol              # 合约：投票系统
test/
  └── Voting.t.sol            # 测试：8 个用例
lib/                          # 依赖库（forge-std）
foundry.toml                  # Foundry 配置
README.md                     # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（8 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（8 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染