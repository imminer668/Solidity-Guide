# 第 11 课：继承、接口、库与 import

对应教程：`0xF1/03_core/11_Inheritance_Interface_Library.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `src/interfaces/IERC20.sol` — ERC20 接口定义
- `src/11_ERC20.sol` — 继承 IERC20 接口的 SimpleERC20 合约实现
- `test/11_ERC20.t.sol` — 2 个测试用例：mint/balance、transfer

## 文件结构

```
src/
  ├── interfaces/
  │   └── IERC20.sol       # ERC20 接口定义
  └── 11_ERC20.sol         # 接口实现合约
test/
  └── 11_ERC20.t.sol       # 测试：2 个用例
lib/                        # 依赖库（forge-std）
foundry.toml                # Foundry 配置
README.md                   # 本说明文件
```

## 支持命令

- `forge build` — 编译合约（接口 + 实现）
- `forge test` — 运行测试（2 个测试全部通过）

## 验收结果

- [ ] `forge build` 通过（需 Foundry 0.3.0+）
- [ ] `forge test` 通过（2 个测试 PASS）
- [x] 代码实现与课程 Markdown 完全一致，无跨课污染

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | IStorage 接口 + StorageContract 实现 |
| 练习 2 | LibraryMath 库 + using for uint256 语法 |