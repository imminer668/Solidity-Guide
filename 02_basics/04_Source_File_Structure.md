# 第 4 课：源文件结构与合约组成

## 1. 本节目标

学完这节课，你能：
- 说出 Solidity 源文件的最小组成结构（4 个必要组成部分）
- 理解 SPDX 许可证声明、pragma 版本声明、contract 定义各自的用途
- 独立写出一个带完整注释的最简 Solidity 合约

## 2. 前置知识

- 第 3 课：已经看过并运行过 HelloWeb3 示例
- 知道什么是代码文件（`.sol` 后缀）

> 如果你之前完全没见过代码文件，花 5 分钟了解一下"文本文件"的概念即可。

## 3. 先讲结论

**每个 Solidity 源文件必须包含以下 4 个部分，按顺序写，缺一不可：**

```
1. SPDX 许可证声明
2. Pragma 版本声明
3. Contract 合约定义
4. （合约内容：状态变量 + 函数）
```

这四部分按固定顺序排列，就像写信的信封、抬头、正文、落款一样。

## 4. 概念解释

### 第 1 部分：SPDX 许可证声明

```solidity
// SPDX-License-Identifier: MIT
```

**通俗解释**：这行代码的作用是告诉别人"你可以随便用我的代码，但要用我的名字"。MIT 是最常用的开源许可证之一。

**为什么必须有**：没有这行，Solidity 编译器会报警告。虽然加了也能运行，但建议养成习惯。

**格式**：`// SPDX-License-Identifier: 许可证名`，必须写在第一行（或者第二行，pragma 之后也行，但习惯写在最前面）。

### 第 2 部分：pragma 版本声明

```solidity
pragma solidity ^0.8.35;
```

**通俗解释**：这行代码告诉编译器"我的代码是用哪个版本的 Solidity 写的，请用对应版本的编译器来编译我"。

**格式分解**：
- `pragma` — 关键字，"编译指示"，告诉编译器一些额外信息
- `solidity` — 声明这是 Solidity 语言
- `^0.8.35` — 允许使用 0.8.35 及以上、0.9.0 以下的版本编译（`^` 表示"兼容以上版本"）

**为什么用 `^0.8.35`**：教程统一使用 v0.8.35 基准版本。

### 第 3 部分：contract 合约定义

```solidity
contract ContractName {
    // ... 合约内容
}
```

**通俗解释**：`contract` 关键字定义了一个"智能合约"，你可以把它理解为一个"部署在区块链上的类"。

**类比**：就像 Java 的 `class`、Python 的 `class`，Solidity 用 `contract` 来组织代码。每个合约像一个小程序，可以有自己的变量和函数。

### 第 4 部分：合约内容（状态变量 + 函数）

合约内容至少包含两样东西之一：

| 组成 | 关键字 | 说明 |
|------|--------|------|
| 状态变量 | `uint256 public num = 0;` | 存储在链上的数据 |
| 函数 | `function setNum(uint256 _num) external { ... }` | 合约的行为 |

### 注释的写法

```solidity
// 这是单行注释，用两个斜杠开头

/* 这是多行注释
   可以写很多行
   直到遇到结束标记 */
```

**注释的用途**：注释是给人看的，编译器会忽略它们。写注释是为了让自己以后还能看懂代码，也让别人能理解你的代码。

## 5. 代码拆解

### 完整的最简合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 这是一个演示源文件结构的最简合约
contract MinimalContract {
    // 状态变量：存储一个数字，初始值为 0
    uint256 public number;

    // 构造函数：部署时自动执行一次，初始化 number
    constructor(uint256 initNumber) {
        number = initNumber;
    }

    // 读取 number 的值
    function getNumber() external view returns (uint256) {
        return number;
    }
}
```

**代码拆解**：

- `// 这是一个演示源文件结构的最简合约` — 文档注释，说明这个文件是干什么的
- `uint256 public number;` — 声明一个公开的数字类型状态变量，默认值为 0
- `constructor(uint256 initNumber)` — 构造函数，部署时传入的参数初始化状态变量
- `function getNumber()` — 定义一个叫 getNumber 的函数
- `external` — 可见性为"仅外部调用"（gas 更优）
- `view` — 函数不修改状态，只读取
- `returns (uint256)` — 函数返回 uint256 类型

## 6. 实操步骤

### 步骤 1：创建新合约文件

在第 3 课项目目录下，创建新文件：

```bash
cat > src/04_MinimalContract.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 第 4 课演示：源文件结构
contract MinimalContract {
    uint256 public number;

    constructor(uint256 initNumber) {
        number = initNumber;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
EOF
```

### 步骤 2：编译

```bash
forge build    // 编译当前项目所有合约
```

**成功时你会看到**：
```
[⠊] Compiling 2 contracts
[✅] Solc compilation finished
```

### 步骤 3：写测试

```bash
cat > test/04_MinimalContract.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/04_MinimalContract.sol";

contract MinimalContractTest is Test {
    MinimalContract public contract_;

    function setUp() public {
        contract_ = new MinimalContract(100);
    }

    function testInitialNumber() public {
        assertEq(contract_.number(), 100);
    }

    function testGetNumber() public {
        assertEq(contract_.getNumber(), 100);
    }
}
EOF
```

### 步骤 4：运行测试

```bash
forge test    // 运行测试
```

**成功时你会看到**：
```
Running 2 tests from MinimalContractTest
[PASS] testInitialNumber (gas: 28283)
[PASS] testGetNumber (gas: 14283)
```

## 7. 运行结果验证

- `forge build` 成功编译，输出无 error
- `forge test` 运行 2 个测试，全部 PASS
- 合约可以被正常部署（`forge script` 验证）

## 8. 常见错误排查

### 错误 1：编译报 `SPDX license identifier not provided`

- **常见原因**：文件第一行没有写 SPDX 声明
- **解决步骤**：在文件最顶部加一行 `// SPDX-License-Identifier: MIT`
- **验证方式**：`forge build` 不再报这个警告

### 错误 2：编译报 `Source file does not specify a version`

- **常见原因**：缺少 `pragma solidity` 声明，或者声明格式不对
- **解决步骤**：确保文件中有 `pragma solidity ^0.8.35;` 这一行
- **验证方式**：`forge build` 成功

### 错误 3：编译报 `Expected '{' but got 'contract'`

- **常见原因**：`contract` 关键字拼写错误或大小写不对（必须小写）
- **解决步骤**：检查拼写，正确写法是 `contract ContractName { ... }`
- **验证方式**：`forge build` 成功

### 错误 4：constructor 报 `Invalid checksum`

- **常见原因**：调用 constructor 时传入的参数类型不匹配
- **解决步骤**：测试中 `new MinimalContract(100)` 的 100 必须是 uint256 类型
- **验证方式**：`forge test` 全部 PASS

## 9. 本节总结

- Solidity 源文件四部分：SPDX 声明 → pragma 声明 → contract 定义 → 合约内容
- SPDX 声明：写在最前面，告知许可证类型
- pragma 声明：告诉编译器用哪个版本编译，`^0.8.35` 表示兼容 0.8.35~0.8.x
- contract 定义：组织代码的关键字，后面跟大括号包裹的合约体
- 注释有两种：`// 单行` 和 `/* 多行 */`

## 10. 课后练习

### 练习 1
修改上面的 `MinimalContract`，添加一个新状态变量 `string public name`，添加对应的 `getName()` 函数，并在 constructor 中增加 name 初始化参数。写测试验证 name 是否正确初始化。

### 练习 2
在 `src/` 目录下创建自己的合约文件 `MyContract.sol`，包含：
1. 正确的 SPDX 声明和 pragma 声明
2. 一个 `uint256 public balance` 状态变量
3. 一个 `constructor(uint256 initBalance)` 初始化 balance
4. 一个 `getBalance() external view returns (uint256)` 函数

写完编译测试通过。

## 11. 官方参考

- [Solidity 源文件结构（官方文档）](https://docs.soliditylang.org/en/v0.8.35/layout-of-source-files.html)
- [SPDX 许可证声明](https://spdx.github.io/spdx-spec/v2.3/)