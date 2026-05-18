# 第 21 课：综合练习 1 — Counter 项目

对应教程：`0xF1/05_projects/21_Project_Counter.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `src/Counter.sol` — Counter 合约（increment/decrement/reset + onlyOwner modifier + events）
- `test/Counter.t.sol` — 8 个测试用例
- `script/Counter.s.sol` — 部署脚本

## 文件结构

```
src/
  └── Counter.sol            # 合约：计数器
test/
  └── Counter.t.sol          # 测试：8 个用例
script/
  └── Counter.s.sol          # 脚本：部署 Counter
lib/                         # 依赖库（forge-std）
foundry.toml                 # Foundry 配置
README.md                    # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（8 个测试全部通过）
- `forge script script/Counter.s.sol --rpc-url http://127.0.0.1:8545 --broadcast` — 部署到 Anvil

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（8 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染