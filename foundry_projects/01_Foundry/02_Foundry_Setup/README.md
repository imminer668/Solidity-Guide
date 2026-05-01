# 第 2 课：安装 Foundry 与初始化项目

对应教程：`0xF1/01_Foundry/02_Foundry_Setup.md`

## 实现范围

本项目为第 2 课提供统一的项目目录结构。

本课为环境课，主要讲解：
- Foundry 安装方法（curl + foundryup）
- `forge init` 初始化项目
- `forge build` 编译合约
- `forge test` 运行测试
- Foundry 项目目录结构（src/、test/、script/、lib/）

**本课无独立业务合约代码**。练习 2 要求学员自己用 `forge init` 创建项目。

## 文件结构

```
src/           # 本课无业务代码（练习 2 由学员自行创建）
test/          # 本课无测试（练习 2 由学员自行创建）
script/         # 本课无脚本（后续课程补充）
lib/            # 依赖库（forge-std）
foundry.toml    # Foundry 配置
README.md       # 本说明文件
```

## 支持命令

- `forge build` — 编译合约。本课无业务代码，输出 `Nothing to compile` 为**正常现象**，并非报错
- `forge test` — 运行测试。本课无合约也无测试，输出 `Nothing to compile` 为**正常现象**，并非报错（因为没有编译产物，forge 不会进入测试阶段）
- `forge script` — 运行脚本。本课无脚本，输出 "no scripts found" 为正常现象

## 验收结果

- [x] `forge build` 通过（本课为空项目，编译无报错）
- [x] `forge test` 通过（本课无测试，符合预期）
- [x] 项目结构合法

## 课后练习要点

| 练习 | 内容 |
|------|------|
| 练习 1 | 安装验证：运行 `forge --version`、`cast --version`、`anvil --version` |
| 练习 2 | 初始化项目：用 `forge init` 创建项目，修改示例合约并跑通全流程 |

> **注意**：本项目为空模板，练习 2 的实际项目需要学员自行用 `forge init` 创建。

---

## 课程学习路径

| 课次 | 课程名称 | 类型 | 说明 |
|------|---------|------|------|
| 第 1 课 | 为什么先学 Foundry | 环境课 | 概念认知，无业务代码 |
| 第 2 课 | 安装 Foundry 与初始化项目 | 环境课 | 工程初始化，练习 2 由学员自建 |
| 第 3 课 | 写第一个合约并完成编译、测试、脚本运行 | 基础语法课 | 开始写业务代码 |
