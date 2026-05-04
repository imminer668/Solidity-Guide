# 第 3 课：写第一个合约并完成编译、测试、脚本运行

## 1. 本节目标

学完这节课，你能：
- 独立写一个极简的 Solidity 合约（HelloWeb3）
- 用 `forge build` 编译合约
- 用 `forge test` 运行测试验证合约行为
- 用 `forge script` 在本地链上运行脚本

**这节课的目标是让你完整走完"写代码→编译→测试→运行"的全部四个步骤。**

## 2. 前置知识

- 第 1 课：了解 Foundry 的三个核心工具（forge / cast / anvil）
- 第 2 课：能成功执行 `forge --version`，了解 Foundry 项目目录结构

## 3. 先讲结论

**你的第一个 Solidity 合约只需要三行代码。**

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;
contract HelloWeb3 { string public _string = "Hello Web3!"; }
```

这三行代码包含了一个 Solidity 合约的最小结构：
- 许可证声明（SPDX）
- 版本声明（pragma）
- 合约定义和内容（contract）

**学完这课，你应该有一种"原来写合约这么简单"的感觉。**

## 4. 概念解释

### Solidity 源文件的最小结构

| 部分 | 语法 | 说明 |
|------|------|------|
| 许可证声明 | `// SPDX-License-Identifier: MIT` | 说明代码可以免费使用、修改、分享 |
| 版本声明 | `pragma solidity ^0.8.35;` | 声明使用哪个版本的 Solidity 编译器 |
| 合约定义 | `contract HelloWeb3 { ... }` | 用 `contract` 关键字定义一个合约 |

### 什么是状态变量

`string public _string = "Hello Web3!";` 是一个**状态变量（state variable）**。

通俗解释：状态变量就是"存在合约里的数据"，所有调用合约的人都能看到或修改它。`public` 关键字表示任何人都可以读取这个变量的值。

### 为什么要加 public

`public` 是**可见性修饰符（visibility modifier）**的一种。声明为 `public` 的变量，Solidity 会自动生成一个同名的 getter 函数（`HelloWeb3._string()`），外部可以直接调用读取。

### 什么是 string 类型

`string` 是 Solidity 的**字符串类型**，用来存储文本数据。`"Hello Web3!"` 就是这个变量的值。

## 5. 代码拆解

### 第一步：创建合约文件

在项目 `src/` 目录下创建 `HelloWeb3.sol`：

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract HelloWeb3 {
    // 公开的字符串状态变量，存储欢迎语
    string public greeting = "Hello Web3!";

    // 获取当前欢迎语
    function getGreeting() external view returns (string memory) {
        return greeting;
    }
}
```

**代码拆解**：
- `// 公开的字符串状态变量，存储欢迎语` — 单行注释，说明这行代码的作用
- `string public greeting` — 声明一个公开的字符串类型变量
- `= "Hello Web3!"` — 变量初始值
- `function getGreeting()` — 定义一个叫 getGreeting 的函数
- `external` — 函数可见性为"仅外部调用"（比 public 更省 gas）
- `view` — 函数只读取状态，不修改状态
- `returns (string memory)` — 函数返回一个 string 类型，memory 表示在内存中临时存储

## 6. 实操步骤

### 步骤 1：清理项目模板中的默认合约

如果你用的是 `forge init` 创建的默认项目，先看一下 `src/` 目录：

```bash
ls src/          // 查看 src/ 目录下的文件
```

模板项目通常有 `Contract.sol`，我们可以删除它或新建我们的文件。这里我们直接覆盖它：

```bash
cat > src/HelloWeb3.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract HelloWeb3 {
    string public greeting = "Hello Web3!";

    function getGreeting() external view returns (string memory) {
        return greeting;
    }
}
EOF
```

### 步骤 2：编译合约

```bash
forge build    // 编译 src/ 目录下所有合约
```

**成功时你会看到**：
```
[⠊] Compiling 1 contract
[✅] Solc compilation finished
```

> 如果你看到 `Error` 或 `警告`，检查一下代码是否完全一致。常见错误：缺少分号、括号不匹配。

### 步骤 3：写测试

在 `test/` 目录下创建 `HelloWeb3.t.sol`：

```bash
cat > test/HelloWeb3.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/HelloWeb3.sol";

contract HelloWeb3Test is Test {
    HelloWeb3 public hello;

    function setUp() public {
        hello = new HelloWeb3();
    }

    function testGreetingValue() public {
        // 验证 greeting 变量的值是 "Hello Web3!"
        assertEq(hello.greeting(), "Hello Web3!");
    }

    function testGetGreeting() public {
        // 验证 getGreeting() 函数返回值
        assertEq(hello.getGreeting(), "Hello Web3!");
    }

    function testGreetingIsPublic() public {
        // 验证 greeting 是 public 的，任何人都能通过合约读取
        string memory retrieved = hello.greeting();
        assertEq(retrieved, "Hello Web3!");
    }
}
EOF
```

**测试代码拆解**：
- `HelloWeb3 public hello;` — 声明一个测试合约类型的变量
- `hello = new HelloWeb3();` — 在 `setUp()` 中部署我们要测试的合约
- `assertEq(a, b)` — 断言 a 等于 b，不相等则测试失败
- `hello.greeting()` — 直接调用 public 变量（Solidity 自动生成 getter）

### 步骤 4：运行测试

```bash
forge test    // 运行所有测试
```

**成功时你会看到**：
```
Running 3 tests from HelloWeb3Test
[PASS] testGreetingValue (gas: 28283)
[PASS] testGetGreeting (gas: 14283)
[PASS] testGreetingIsPublic (gas: 14283)
```

三个测试全部通过（PASS），没有任何失败（FAIL）。

### 步骤 5：用 cast 调用合约（可选）

先确保本地链 `anvil` 在运行（另一个终端窗口）：

```bash
anvil    // 启动本地链，不要关闭这个终端
```

然后用 cast 在本地链上调用合约：

```bash
# 读取 greeting 的值
cast call <合约地址> "greeting()(string)"

# 读取 getGreeting() 的返回值
cast call <合约地址> "getGreeting()(string)"
```

> `<合约地址>` 需要替换为实际的合约部署地址，下一步步骤 6 会告诉你怎么部署。

### 步骤 6：写部署脚本并部署

在 `script/` 目录下创建 `HelloWeb3.s.sol`：

```bash
cat > script/HelloWeb3.s.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Script.sol";
import "src/HelloWeb3.sol";

contract HelloWeb3Script is Script {
    function run() external {
        vm.startBroadcast();

        HelloWeb3 hello = new HelloWeb3();
        console.log("Contract deployed at:", address(hello));

        vm.stopBroadcast();
    }
}
EOF
```

**脚本拆解**：
- `import "forge-std/Script.sol"` — 导入 Foundry 的脚本工具库
- `HelloWeb3Script is Script` — 创建继承自 Script 的部署脚本
- `run()` — 脚本入口，forge script 会自动执行这个函数
- `vm.startBroadcast()` — 开始广播交易（相当于"开始部署"）
- `new HelloWeb3()` — 部署合约，返回合约地址
- `console.log()` — 在终端输出部署地址（方便我们复制使用）
- `vm.stopBroadcast()` — 结束广播

### 步骤 7：执行部署脚本

> **注意**：本地 Anvil 链部署时，Foundry 会自动使用 Anvil 的第一个默认账户（含 10000 ETH），无需额外指定私钥。如使用其他测试网或主网，需要通过 `--private-key` 或 `-k` 选项提供发送者私钥。

```bash
forge script script/HelloWeb3.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

> 需要确保 `anvil` 在另一个终端窗口运行。

**成功时你会看到**：
```
Script ran successfully.
Contract deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
```

恭喜！你的合约已经部署到本地链上了。`0x5FbDB...` 就是合约地址。

### 步骤 8：用 cast 验证部署后的合约

用刚才输出的合约地址，验证合约确实在工作：

```bash
# 读取 greeting 值
cast call <合约地址> "greeting()(string)"

# 调用 getGreeting()
cast call <合约地址> "getGreeting()(string)"
```

两个调用都应该返回 `"Hello Web3!"`。

## 7. 运行结果验证

这一节课的"成功"标准是：

1. `forge build` 成功编译，输出无 error
2. `forge test` 运行 3 个测试，全部 PASS
3. `forge script` 成功部署，输出包含 `Contract deployed at:`
4. `cast call` 调用部署后的合约，返回正确值 `"Hello Web3!"`

**四步全部通过，说明你完成了一次完整的 Solidity 开发闭环。**

## 8. 常见错误排查

### 错误 1：forge build 失败，报 `cannot find contract`

- **常见原因**：合约文件名和内容里的 contract 名不一致
- **解决步骤**：
  1. 检查 `src/HelloWeb3.sol` 中的 `contract` 名是否为 `HelloWeb3`
  2. 检查 `forge.toml` 中 `src` 路径是否正确
  3. 确认文件确实在 `src/` 目录下
- **验证方式**：`ls src/` 能看到 `HelloWeb3.sol`

### 错误 2：forge test 失败，报 `failed to call greeting`

- **常见原因**：`testGreetingIsPublic` 测试里 `hello.greeting()` 返回的类型和 `assertEq` 期望的类型不匹配
- **解决步骤**：
  1. `greeting()` 返回的是 `string memory`
  2. 确保 `assertEq` 的第二个参数是字符串 `"Hello Web3!"`，不要加类型转换
- **验证方式**：三个测试全部 PASS

### 错误 3：cast call 失败，报 `calldata too short`

- **常见原因**：函数签名写错了（注意括号 `()` 里如果有参数要写类型）
- **解决步骤**：
  1. `greeting()(string)` — 无参数，返回 string
  2. `getGreeting()(string)` — 无参数，返回 string
  3. 检查括号是否完整，参数类型是否正确
- **验证方式**：调用成功且返回值正确

### 错误 4：forge script 失败，报 `network does not exist`

- **常见原因**：`anvil` 没有启动，或者 RPC URL 写错了
- **解决步骤**：
  1. 确认 `anvil` 在另一个终端窗口运行中
  2. 确认 RPC URL 为 `http://127.0.0.1:8545`（不是 `http://localhost:8545`）
  3. 确认 URL 没有多余的空格
- **验证方式**：`anvil` 终端窗口保持运行，`forge script` 成功输出地址

## 9. 本节总结

- Solidity 合约的最小结构只需要三行：SPDX + pragma + contract
- `string public` 变量会自动生成 getter 函数
- 完整的开发闭环：写代码 → `forge build` → `forge test` → `forge script` 部署 → `cast` 调用验证
- 这一课的三个核心命令必须记住：
  - `forge build` — 编译
  - `forge test` — 测试
  - `forge script` — 部署

## 10. 课后练习

### 练习 1
修改 `HelloWeb3.sol`，把欢迎语改成你自己的名字（比如 `"Hello, Alice!"`），修改后重新编译、测试、部署，验证 `cast call` 返回值是你修改后的内容。

### 练习 2
在 `HelloWeb3.sol` 中添加一个新函数 `setGreeting(string memory newGreeting) external`，允许外部修改欢迎语。写对应的测试验证：
1. 初始 greeting 值是 "Hello Web3!"
2. 调用 `setGreeting("Hello, Blockchain!")` 后，greeting 值变为 "Hello, Blockchain!"
3. `getGreeting()` 返回新的值