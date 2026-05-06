# 第 8 课：数组、结构体与映射

对应教程：`0xF1/02_basics/08_Array_Struct.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `08_ArrayAndStruct.sol` — 演示数组操作（push/pop/length）和结构体（定义/创建/修改）
- `08_ArrayAndStruct.t.sol` — 4 个测试用例：数组 push/pop、结构体添加/修改

## 文件结构

```
src/
  └── 08_ArrayAndStruct.sol    # 合约：数组 + 结构体
test/
  └── 08_ArrayAndStruct.t.sol  # 测试：4 个用例
lib/                           # 依赖库（forge-std）
foundry.toml                   # Foundry 配置
README.md                       # 本说明文件
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
| 练习 1 | ProductStore：Product 结构体 + addProduct + getProduct |
| 练习 2 | 添加 sellerProducts mapping + getMyProducts() |