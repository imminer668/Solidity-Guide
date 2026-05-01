# 第 1 课：为什么先学 Foundry

## 1. 本节目标

学完这节课，你能：
- 说出 Foundry 是什么，以及它解决了什么问题
- 理解 Solidity 开发中"写代码→编译→测试→运行"的完整闭环
- 知道这套教程的学习路径和最终目标

## 2. 前置知识

- 知道什么是 Solidity（用于编写以太坊智能合约的编程语言）
- 知道什么是合约部署（把代码发送到区块链上，使其可被调用）

> 如果你对这两个概念完全陌生，建议先花 10 分钟阅读以太坊基础概念，再来继续。

## 3. 先讲结论

**学 Solidity，最高效的工具是 Foundry**。

它同时包含了：编译器（把你的代码转成字节码）、测试框架（自动运行测试）、脚本工具（部署和交互），三合一，不需要在多个工具之间切换。

**这套教程选择 Foundry 作为唯一工具链**，让读者从第一课开始就能独立完成"写代码→编译→测试→运行"的全流程，而不是停在"看代码"阶段。

## 4. 概念解释

### Foundry 是什么

Foundry 是一个 Solidity 开发工具链，由三个核心工具组成：

| 工具 | 作用 | 类比 |
|------|------|------|
| `forge` | 编译和测试 | 相当于"编译器 + 测试框架" |
| `cast` | 与合约交互 | 相当于"命令行遥控器" |
| `anvil` | 本地测试链 | 相当于"本地模拟以太坊" |

### 为什么不用 Remix

Remix 是一个在线 IDE，打开浏览器就能用。它适合快速体验，但存在两个问题：

1. **环境不掌握在你自己手里**：断网就用不了，换电脑要重新配置
2. **无法与真实开发流程接轨**：真实项目都是本地开发，不需要依赖浏览器

Foundry 是本地工具，环境在你自己的电脑上，不受网络限制，而且与真实以太坊开发工作流完全一致。

### 为什么不用 Hardhat

Hardhat 也是一个流行的本地开发环境，基于 JavaScript/TypeScript。两者对比：

| 对比项 | Foundry | Hardhat |
|--------|---------|---------|
| 语言 | Solidity 原生 | 需要写 JavaScript/TypeScript 脚本 |
| 测试速度 | 快（Rust 实现） | 中等（Node.js 实现） |
| 学习曲线 | 低（Solidity 原生，测试直接用 Solidity 写） | 中（需要了解 Node.js） |
| 调试体验 | 极好（`forge debug`） | 中等 |

**对于新手来说，Foundry 更友好**：配置文件少、命令简单、测试语法直接用 Solidity 写。

### Solidity 开发闭环

一次完整的 Solidity 开发，包含以下四个步骤：

```
1. 写代码    →  用 .sol 文件编写合约源代码
2. 编译      →  用 forge build 把代码转成字节码
3. 测试      →  用 forge test 自动跑测试，验证合约行为
4. 运行      →  用 cast 或 forge script 部署到链上并交互
```

这四个步骤缺一不可。**很多教程只做到第 1 步"写代码"，新手看完还是不知道"怎么跑起来"**。本教程要求每一课都做到这四步的闭环。

## 5. 代码拆解

（本节无代码示例，纯概念讲解）

## 6. 实操步骤

### 检查你的电脑上有没有 Foundry

打开终端，执行以下命令：

```bash
forge --version
```

**成功时你会看到**：类似 `forge 0.3.0 (ABC123 2024-01-01)` 的版本号输出

**失败时你会看到**：`command not found: forge`，说明还没安装 → 去第 2 课看安装步骤

### 查看 Foundry 完整工具列表

```bash
forge --help    // 查看编译和测试命令帮助
cast --help     // 查看交互命令帮助
anvil --help   // 查看本地链命令帮助
```

## 7. 运行结果验证

- 如果 `forge --version` 返回了版本号，说明 Foundry 已安装成功，可以直接跳到第 2 课。
- 如果提示 `command not found`，说明还没装，第 2 课会详细讲安装步骤。

## 8. 常见错误排查

### 错误 1：终端提示 `command not found: forge`
- **常见原因**：Foundry 没有安装，或者安装后没有配置 PATH
- **解决步骤**：
  1. Mac/Linux 用户：在终端运行
     ```bash
     curl -L https://foundry.paradigm.xyz | bash
     foundryup
     ```
  2. Windows 用户：使用 WSL2 或者参考 Foundry 官方文档的 Windows 安装方式
  3. 安装完成后，重新打开一个终端窗口，再试 `forge --version`
- **验证方式**：输入 `forge --version` 有版本号输出即为成功

### 错误 2：`curl: command not found`
- **常见原因**：系统没有 curl 命令（Mac 自带，Windows 需要安装）
- **解决步骤**：Windows 用户建议安装 [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)，或者参考 [Foundry 安装文档](https://book.getfoundry.sh/getting-started/installation)
- **验证方式**：`curl --version` 有输出即为成功

## 9. 本节总结

- Foundry 是 Solidity 开发的三合一工具链（forge + cast + anvil）
- 它能让你在本地完成"写代码→编译→测试→运行"的完整闭环
- 相比 Remix 和 Hardhat，Foundry 对新手更友好、学习曲线更低
- 下一课我们将安装 Foundry 并初始化第一个项目

## 10. 课后练习

### 练习 1
在你的电脑上安装 Foundry（参考第 2 课），安装完成后在终端输入 `forge --version`，确保能看到版本号输出。把输出结果截图保存。

### 练习 2
阅读 Foundry 官方文档的 [What's Foundry?](https://book.getfoundry.sh/) 页面，了解三个核心工具（forge/cast/anvil）的功能概述。