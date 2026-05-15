# 第 20 课：常见安全问题与风险提醒

对应教程：`0xF1/04_advanced/20_Security_Risks.md`

## 实现范围

本项目实现了课程中讲到的以下内容：

- `20_SecurityExamples.sol` — 演示重入攻击漏洞与防御（VulnerableVault + SafeVault）
- `20_SecurityExamples.t.sol` — 2 个测试用例：正常存取、多次提取

## 文件结构

```
src/
  └── 20_SecurityExamples.sol    # 合约：漏洞与安全对比
test/
  └── 20_SecurityExamples.t.sol  # 测试：2 个用例
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
| 练习 1 | 重入攻击练习：攻击 VulnerableVault |
| 练习 2 | 安全Vault：添加 events +onlyOwner +紧急暂停功能 |