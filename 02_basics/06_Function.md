# 第 6 课：函数：定义、返回值、可见性

## 1. 本节目标

学完这节课，你能：
- 理解函数的基本组成部分（参数、返回值、可见性、函数体）
- 掌握四种可见性修饰符的区别和使用场景（external / public / internal / private）
- 能写带命名返回值的函数
- 能用 `return` 和 `returns` 两种方式返回值

## 2. 前置知识

- 第 4 课：理解合约的基本结构
- 第 5 课：理解 Solidity 的基本类型

## 3. 先讲结论

**函数是合约的"行为"，定义一个函数就像给合约编写一个"指令"。**

一个完整的 Solidity 函数包含：

```
function 函数名(参数) 可见性 状态修饰符 returns(返回值类型) { 函数体 }
```

**四种可见性决定了谁能调用这个函数：**
- `external`：只能从合约外部调用（gas 最优，推荐优先使用）
- `public`：可以从任何地方调用（外部 + 内部）
- `internal`：只能从当前合约或继承的子合约调用
- `private`：只能从当前合约调用（不被继承）

## 4. 概念解释

### 函数的基本结构

```solidity
function getValue(uint256 input) external view returns (uint256) {
    return input * 2;
}
```

**分解**：
- `function` — 关键字，定义函数
- `getValue` — 函数名（自定义）
- `(uint256 input)` — 参数（入参）
- `external` — 可见性（仅外部调用）
- `view` — 状态修饰符（只读）
- `returns (uint256)` — 返回值类型
- `{ return input * 2; }` — 函数体

### 四种可见性详解

#### external（推荐优先使用）

```solidity
function setValue(uint256 _value) external {
    storedValue = _value;
}
```

**特点**：
- 只能从合约外部调用（通过 `合约地址.函数名()` 或 `call()` 调用）
- **gas 最低**，因为 Solidity 会优化 external 函数的调用
- 不能被内部调用

**使用场景**：当函数只被外部调用时，优先使用 `external`。

#### public（最宽松）

```solidity
function getValue() public view returns (uint256) {
    return storedValue;
}
```

**特点**：
- 可以从任何地方调用（外部账户、其他合约、内部调用）
- Solidity 会自动为 public 变量生成 getter 函数

**使用场景**：如果函数需要被内部调用且被外部调用，用 `public`。

#### internal（仅内部）

```solidity
function _calculateTax(uint256 amount) internal pure returns (uint256) {
    return amount * 10 / 100;
}
```

**特点**：
- 只能从当前合约或子合约内部调用
- 子合约不能调用父合约的 private 函数，但可以调用 internal 函数

**使用场景**：作为内部辅助函数，不对外开放。

#### private（仅当前合约）

```solidity
function _secretHash() private view returns (bytes32) {
    return keccak256(abi.encode(msg.sender));
}
```

**特点**：
- 只能从当前合约调用，子合约也无法访问
- 名字带下划线是社区惯例，表示"私有函数"

**使用场景**：仅在当前合约内部使用的辅助函数。

### 状态修饰符

| 修饰符 | 说明 | 能读取状态吗 | 能修改状态吗 |
|--------|------|------------|------------|
| `view` | 只读函数 | ✅ | ❌ |
| `pure` | 纯函数 | ❌ | ❌ |
| 无（默认） | 可写函数 | ✅ | ✅ |

**通俗解释**：
- `view`：类似"读取"，只看不改
- `pure`：类似"纯计算"，既不看也不改
- 无修饰符：类似"写入"，可以修改状态

### 返回值的三种写法

#### 写法 1：return 关键字

```solidity
function add(uint256 a, uint256 b) external pure returns (uint256) {
    return a + b;
}
```

**最直接**，函数体里用 `return` 返回结果。

#### 写法 2：命名返回值

```solidity
function multiply(uint256 a, uint256 b) external pure returns (uint256 result) {
    result = a * b; // 直接给返回值变量赋值，不需要 return
}
```

**特点**：在 `returns` 里给返回值变量起名字，函数体里直接给它赋值即可。

#### 写法 3：return + 命名返回值（混合）

```solidity
function subtract(uint256 a, uint256 b) external pure returns (uint256 difference) {
    return a - b; // 用 return 返回，但也可以写 difference = a - b
}
```

### 函数参数

```solidity
function transfer(address to, uint256 amount) external {
    // 参数是外部传入的值，在函数体内使用
}
```

**参数命名规范**：
- 参数名前加下划线 `_to` / `_amount` 是社区惯例，用来区分全局状态变量和参数

### 构造函数的特殊写法

```solidity
constructor(uint256 _initValue) {
    storedValue = _initValue;
}
```

- 构造函数没有 `function` 关键字，也没有可见性
- `constructor` 在部署时自动执行一次
- 一个合约只能有一个构造函数

## 5. 代码拆解

### 完整示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract FunctionDemo {
    uint256 public storedValue;

    // 构造函数：初始化 storedValue
    constructor(uint256 _initValue) {
        storedValue = _initValue;
    }

    // 只读函数，用 external view
    function getStoredValue() external view returns (uint256) {
        return storedValue;
    }

    // 写入函数，无修饰符
    function setStoredValue(uint256 _value) external {
        storedValue = _value;
    }

    // 带命名返回值的纯函数
    function calculate(uint256 a, uint256 b)
        external
        pure
        returns (uint256 sum, uint256 product)
    {
        sum = a + b;
        product = a * b;
    }

    // 内部辅助函数
    function _double(uint256 _value) internal pure returns (uint256) {
        return _value * 2;
    }

    // 使用内部函数
    function doubleStoredValue() external view returns (uint256) {
        return _double(storedValue);
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/06_Function.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract FunctionDemo {
    uint256 public storedValue;

    constructor(uint256 _initValue) {
        storedValue = _initValue;
    }

    function getStoredValue() external view returns (uint256) {
        return storedValue;
    }

    function setStoredValue(uint256 _value) external {
        storedValue = _value;
    }

    function calculate(uint256 a, uint256 b)
        external
        pure
        returns (uint256 sum, uint256 product)
    {
        sum = a + b;
        product = a * b;
    }

    function _double(uint256 _value) internal pure returns (uint256) {
        return _value * 2;
    }

    function doubleStoredValue() external view returns (uint256) {
        return _double(storedValue);
    }
}
EOF
```

### 步骤 2：编译

```bash
forge build
```

### 步骤 3：写测试

```bash
cat > test/06_Function.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/06_Function.sol";

contract FunctionDemoTest is Test {
    FunctionDemo public demo;

    function setUp() public {
        demo = new FunctionDemo(10);
    }

    function testInitialValue() public {
        assertEq(demo.storedValue(), 10);
    }

    function testSetValue() public {
        demo.setStoredValue(99);
        assertEq(demo.storedValue(), 99);
    }

    function testGetValue() public {
        assertEq(demo.getStoredValue(), 10);
    }

    function testCalculate() public {
        (uint256 sum, uint256 product) = demo.calculate(3, 5);
        assertEq(sum, 8);
        assertEq(product, 15);
    }

    function testDoubleStoredValue() public {
        assertEq(demo.doubleStoredValue(), 20);
    }
}
EOF
```

### 步骤 4：运行测试

```bash
forge test
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 5 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：编译报 `Statement has no effect`

- **常见原因**：在 pure 函数里读取了状态变量
- **解决步骤**：
  1. 如果函数不读取状态，用 `pure` 修饰符
  2. 如果函数读取状态但不改，用 `view` 修饰符
  3. 如果函数修改状态，去掉 view/pure
- **验证方式**：`forge build` 成功

### 错误 2：编译报 `Visibility must be declared`

- **常见原因**：函数缺少可见性修饰符
- **解决步骤**：给函数加上 `external` / `public` / `internal` / `private` 之一
- **验证方式**：`forge build` 成功

### 错误 3：编译报 `Return arguments not allowed`

- **常见原因**：函数声明了返回值但函数体里没有返回（缺少 `return` 或没给命名返回值变量赋值）
- **解决步骤**：
  1. 检查 `returns (类型)` 声明是否和函数体匹配
  2. 确认函数体里有 `return 值;` 语句
- **验证方式**：`forge build` 成功

### 错误 4：编译报 `Internal or private function must be called`

- **常见原因**：在合约外部调用了 `internal` 或 `private` 函数
- **解决步骤**：
  1. `internal` / `private` 函数不能从外部调用
  2. 如果需要从外部调，改为 `external`
  3. 如果需要内部调，通过另一个内部/公开函数间接调用
- **验证方式**：`forge build` 成功

## 9. 本节总结

- 函数由 6 个部分组成：function 关键字 + 函数名 + (参数) + 可见性 + 状态修饰符 + returns
- 四种可见性：external（仅外部）→ public（任何地方）→ internal（内部+继承）→ private（仅当前合约）
- `external` 是 gas 最优的，优先使用
- 返回值写法：`return x` 或 `returns(uint value)` + `value = x`
- 构造函数 `constructor` 在部署时执行一次，无可见性

## 10. 课后练习

### 练习 1
写一个 `BankContract`，包含：
- `address public owner`
- `constructor(address _owner)` 初始化 owner
- `function deposit() external payable` 存 ETH（存入 msg.value）
- `function withdraw(uint256 amount) external` 取 ETH（仅 owner）
- `function getBalance() external view returns (uint256)` 查询余额

用测试验证：存 10 ETH 后 getBalance 返回 10，取 5 ETH 后返回 5。

### 练习 2
写一个纯函数 `average(uint256 a, uint256 b, uint256 c) external pure returns (uint256 avg)`，计算三个数的平均值。用命名返回值写法。写测试验证 average(10, 20, 30) = 20。

## 11. 官方参考

- [函数（Functions）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#functions)
- [可见性（Visibility）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#visibility-and-getters)
- [构造函数（Constructor）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#constructors)