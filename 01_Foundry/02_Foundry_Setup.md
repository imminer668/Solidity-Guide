# 第 2 课：安装 Foundry 与初始化项目

## 1. 本节目标

学完这节课，你能：
- 在你的电脑上成功安装 Foundry
- 创建一个 Foundry 项目并理解其目录结构
- 掌握 `forge init`、`forge build`、`forge test` 三个核心命令

## 2. 前置知识

- 会用基本命令行操作（cd、ls、mkdir）
- 知道什么是终端/命令行

> 如果你从来没开过终端，搜索"Mac 打开终端"或"Windows 打开 CMD"即可。

## 3. 先讲结论

**安装 Foundry 只有两条命令，30 秒搞定。**

初始化项目也只需一条命令。学会之后，你就可以在任何时候用 Foundry 开发 Solidity 了。

## 4. 概念解释

### 安装 Foundry

Foundry 由 Paradigm 团队维护，安装方式非常简洁。

#### Mac / Linux 安装方式

打开终端，依次执行：

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

第一条命令下载安装脚本，第二条命令执行安装。

#### Windows 安装方式

Windows 用户推荐使用 **WSL2**（Windows Subsystem for Linux），在 WSL2 环境下执行上述两条命令即可。

如果不想装 WSL2，也可以参考 [Foundry 官方 Windows 安装文档](https://book.getfoundry.sh/getting-started/installation)。

### 安装验证

安装完成后，**重新打开一个全新的终端窗口**（不是之前已经打开的那个），然后输入：

```bash
forge --version
```

**成功时**：显示类似 `forge 0.3.0 (abc123 2024-01-01)` 的版本号

**失败时**：显示 `command not found: forge`，需要重新执行 `foundryup`

### 初始化 Foundry 项目

找一个你想放项目的目录（比如 `~/projects/solidity`），执行：

```bash
forge init my-first-project
```

这会在当前目录下创建一个叫 `my-first-project` 的文件夹，里面包含 Foundry 项目模板。

**成功时你会看到**：
```
Initializing forge project...
Active profile: default
Install dependencies from remappings.txt...
```

### Foundry 项目目录结构

初始化完成后，`my-first-project` 目录结构如下：

```
my-first-project/
├── lib/              // 第三方库（ Foundry 默认用 forge-std）
├── src/              // 你的源代码放这里  ← 主要工作区
│   └── Contract.sol  // 示例合约
├── test/             // 你的测试代码放这里
│   └── Contract.t.sol // 示例测试
├── script/           // 部署脚本放这里
│   └── Contract.s.sol
├── foundry.toml     // Foundry 配置文件
└── remappings.txt    // 导入路径映射配置
```

**你最常打交道的三个目录**：
- `src/` — 写合约代码的地方
- `test/` — 写测试代码的地方
- `script/` — 写部署脚本的地方

## 5. 代码拆解

### 示例合约（src/Contract.sol）

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 这是一个示例合约，展示了 Foundry 项目的最小结构
contract Contract {
    uint256 public num;

    function setNum(uint256 _num) external {
        num = _num;
    }

    function getNum() external view returns (uint256) {
        return num;
    }
}
```

**代码拆解**：
- `// SPDX-License-Identifier: MIT` — 许可证声明，每份代码都要有
- `pragma solidity ^0.8.35;` — 声明使用 Solidity 0.8.35 版本
- `contract Contract` — 定义一个叫 Contract 的合约
- `uint256 public num;` — 声明一个公开的数值变量
- `setNum()` / `getNum()` — 两个函数，分别用于设置和获取数值

### 示例测试（test/Contract.t.sol）

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/Contract.sol";

contract ContractTest is Test {
    Contract public contract;

    function setUp() public {
        contract = new Contract();
    }

    function testSetAndGet() public {
        contract.setNum(42);
        assertEq(contract.getNum(), 42);
    }
}
```

**测试代码拆解**：
- `import "forge-std/Test.sol";` — 导入 Foundry 标准测试库
- `contract ContractTest is Test` — 创建一个继承自 Test 的测试合约
- `setUp()` — 测试前自动执行的初始化函数
- `testSetAndGet()` — 以 `test` 开头的函数，测试框架自动识别并执行
- `assertEq()` — 断言相等，如果不相等则测试失败

## 6. 实操步骤

### 步骤 1：安装 Foundry

```bash
curl -L https://foundry.paradigm.xyz | bash    // 下载安装脚本
foundryup                                    // 执行安装
```

### 步骤 2：验证安装（重新打开终端后）

```bash
forge --version    // 验证 forge 安装成功
cast --version    // 验证 cast 安装成功
anvil --version   // 验证 anvil 安装成功
```

三个命令都有版本号输出即为全部安装成功。

### 步骤 3：初始化项目

```bash
cd ~/projects                // 进入你想放项目的目录（可以是任意目录）
forge init my-first-project  // 在当前目录创建 Foundry 项目
cd my-first-project         // 进入项目目录
ls -la                      // 查看项目结构
```

### 步骤 4：编译合约

```bash
forge build    // 编译 src/ 目录下所有合约
```

**成功时你会看到**：
```
[⠊] Compiling X contracts
[⠒] Compiling Y contracts
[✅] Found X compiler warning(s)
Compiler build finished
```

**失败时**（通常是语法错误）：会显示具体文件和行号，根据提示修改即可。

### 步骤 5：运行测试

```bash
forge test    // 运行 test/ 目录下所有测试
```

**成功时你会看到**：
```
Running 1 test from ContractTest
[PASS] testSetAndGet (gas: XXXXX)
```

**失败时**：会显示 `FAIL` 和哪个测试没通过以及原因。

### 步骤 6：（可选）启动本地链并部署

```bash
anvil    // 在另一个终端窗口启动本地链（会阻塞，不要关）
```

在项目目录另开终端，执行部署脚本：

```bash
forge script script/Contract.s.sol --rpc-url http://127.0.0.1:8545 --private-key 0x... --broadcast
```

> 注意：上述命令需要替换 `--private-key` 为真实的私钥（测试网上可以用 `anvil` 提供的默认私钥）。

## 7. 运行结果验证

以下三个验证点全部通过，说明你的环境已经可以正常使用：

1. `forge --version` 有版本号输出
2. `forge build` 成功编译（0 failures）
3. `forge test` 成功运行（1 test passed）

## 8. 常见错误排查

### 错误 1：安装脚本执行失败（curl 报错）

- **常见原因**：网络问题，或者系统权限不够
- **解决步骤**：
  1. 确保网络正常
  2. Mac/Linux 用户尝试在命令前加 `sudo`：
     ```bash
     sudo curl -L https://foundry.paradigm.xyz | bash
     ```
  3. 如果还有问题，尝试手动下载：参考 https://github.com/foundry-rs/foundry
- **验证方式**：`foundryup` 能执行即为成功

### 错误 2：forge 版本老旧，不提示更新

- **常见原因**：之前装过老版本，没有自动更新
- **解决步骤**：
  ```bash
  foundryup    // 直接升级到最新版本
  ```
- **验证方式**：`forge --version` 显示新版本号

### 错误 3：forge build 失败，报 `Solc compilation failed`

- **常见原因**：语法错误，通常在错误提示行附近
- **解决步骤**：
  1. 看错误信息，会显示 `Error:` 和具体文件名和行号
  2. 去对应文件检查对应行，一般是缺少分号、括号不匹配等
  3. 修复后重新 `forge build`
- **验证方式**：`forge build` 显示 `Compiler build finished` 无 error

### 错误 4：forge test 失败，报 `Unknown cheatcode`

- **常见原因**：测试代码中用了 cheatcode（如 `vm.createAccount`），但忘记导入 `forge-std`
- **解决步骤**：在测试文件顶部加：
  ```solidity
  import "forge-std/Test.sol";
  ```
- **验证方式**：`forge test` 正常运行

### 错误 5：forge test 失败，报 `setUp` failed

- **常见原因**：`setUp()` 函数里的初始化代码出错了，通常是合约部署失败
- **解决步骤**：
  1. 检查 `setUp()` 里的 `new Contract()` 是否写对
  2. 检查 `src/` 目录下的合约是否编译成功（`forge build` 先跑一遍）
- **验证方式**：`forge build` 成功后，`forge test` 的 setUp 不再失败

## 9. 本节总结

- Foundry 安装只需两条命令（`curl ... | bash` + `foundryup`）
- 项目初始化只需一条命令（`forge init 项目名`）
- `forge build` 编译、`forge test` 测试、`anvil` 本地链，是三个最核心的命令
- 下一课我们将写第一个自己的合约，并完整跑通"写→编译→测试→运行"全流程

## 10. 课后练习

### 练习 1
安装 Foundry（如果还没装），运行 `forge --version`、`cast --version`、`anvil --version`，确保三个命令都有输出。

### 练习 2
用 `forge init` 创建你自己的项目，修改 `src/Contract.sol` 中的数字为你的幸运数字，重新 `forge build` 编译、`forge test` 测试，截图保存测试成功的输出。