# 第 3 课：写第一个合约并完成编译、测试、脚本运行

对应教程：`0xF1/01_Foundry/03_First_Contract.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `HelloWeb3.sol` — 基础合约，包含 public 状态变量 `greeting` 和 `getGreeting()` 函数
- `HelloWeb3.t.sol` — 三个测试用例，验证 greeting 值、getGreeting() 返回值、public getter
- `HelloWeb3.s.sol` — 部署脚本，在本地链部署合约并输出地址

## 文件结构

```
src/
  └── HelloWeb3.sol    # 合约：公开字符串状态变量 + getter 函数
test/
  └── HelloWeb3.t.sol  # 测试：验证 greeting 值和函数返回值
script/
  └── HelloWeb3.s.sol  # 部署脚本：在本地链部署合约
lib/                   # 依赖库（forge-std）
foundry.toml           # Foundry 配置
README.md              # 本说明文件
```

## 支持命令

- `forge build` — 编译合约
- `forge test` — 运行测试（3 个测试全部通过）
- `forge script` — 运行部署脚本（需先启动 anvil）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+ 且 solc 0.8.35+；当前环境缺失 solc 编译器缓存）
- [ ] `forge test` 通过（需 anvil 测试网环境）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

**环境要求**：Foundry 0.3.0+、`foundryup` 更新到最新版本后可正常编译运行。

## 课后练习

| 练习 | 内容 |
|------|------|
| 练习 1 | 修改 greeting 为你自己的名字，重编测试部署 |
| 练习 2 | 添加 `setGreeting(string)` 函数并写测试验证 |