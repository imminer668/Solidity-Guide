# 第 16 课：ABI 编解码与 Selector

对应教程：`0xF1/03_core/16_ABI_Selector.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `16_ABIDemo.sol` — 演示 ABI 编解码（abi.encode/decode/encodeWithSignature）和 Selector 计算
- `16_ABIDemo.t.sol` — 3 个测试用例：encode/decode、selector 计算、encodeWithSig

## 文件结构

```
src/
  └── 16_ABIDemo.sol    # 合约：ABI 编解码演示
test/
  └── 16_ABIDemo.t.sol  # 测试：3 个用例
lib/                    # 依赖库（forge-std）
foundry.toml            # Foundry 配置
README.md               # 本说明文件
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
| 练习 1 | ABIPractice：encodeUser/decodeUser + 验证 |
| 练习 2 | cast sig 命令验证 Selector |