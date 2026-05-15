# 第 19 课：Try-Catch 与异常处理

## 1. 本节目标

学完这节课，你能：
- 理解 Try-Catch 的用途（捕获外部调用中的异常）
- 能在外部调用和合约创建中使用 Try-Catch
- 理解 Panic 和 Error 两种错误类型的区别
- 能在 Foundry 测试中验证 Try-Catch 行为

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 9 课：理解错误处理（require / revert / assert）
- 第 15 课：理解 call 调用

## 3. 先讲结论

**Try-Catch 让你"捕获"外部调用中的异常，避免整个交易 revert。**

当合约 A 调用合约 B 的函数时，如果 B revert 了，A 的整个交易也会 revert。Try-Catch 可以让你"抓住"这个异常，继续执行。

**适用场景**：
- 调用不信任的外部合约
- 创建可能失败的合约
- 需要对异常做不同处理的业务逻辑

## 4. 概念解释

### Try-Catch 基本语法

```solidity
// 语法
try externalContract.someFunction() returns (returnType1, returnType2) {
    // 调用成功时执行
} catch Error(string memory reason) {
    // 捕获 require(false, "reason") / revert("reason")
} catch (bytes memory rawData) {
    // 捕获其他类型的错误（如 Panic(assert失败)）
}
```

### 两种主要错误类型

#### Error（字符串错误）

```solidity
// 触发方式
revert("Insufficient balance");
require(condition, "Insufficient balance");
```

**catch 方式**：
```solidity
catch Error(string memory reason) {
    // reason = "Insufficient balance"
}
```

#### Panic（断言错误）

```solidity
// 触发方式
assert(condition); // condition 为 false 时触发 Panic
```

**注意**：assert 失败触发的是 `Panic(uint256)` 类型，不是 `Error(string)`。

**catch 方式**：
```solidity
catch (bytes memory rawData) {
    // rawData 是 Panic 编码，可进一步解码
}
```

### Try-Catch 用在合约创建

```solidity
contract Fails {
    constructor(uint256 a) {
        require(a != 0, "a cannot be zero");
        assert(a != 1); // 故意 assert，测试 Panic
    }
}

contract Creator {
    function createAndCall(uint256 a) external returns (bool success) {
        try new Fails(a) returns (Fails f) {
            // 创建成功
            success = true;
        } catch Error(string memory reason) {
            // require/revert("reason") 失败
            console.log("Error:", reason);
            success = false;
        } catch (bytes memory rawData) {
            // assert 失败（Panic）
            success = false;
        }
    }
}
```

### Try-Catch 用在外部调用

```solidity
contract Caller {
    function callFunction(address _target, uint256 _value) external returns (bool) {
        try SomeInterface(_target).someFunction(_value) returns (uint256 result) {
            // 成功了，有返回值
            return result > 0;
        } catch Error(string memory reason) {
            // require/revert 失败
            return false;
        } catch (bytes memory) {
            // 其他错误
            return false;
        }
    }
}
```

### Panic 错误代码

assert 失败时，Panic 编码包含错误代码：

| Panic 代码 | 含义 |
|-----------|------|
| 0x01 | 0.8.0 之前 assert 失败 |
| 0x11 | 算术溢出/下溢 |
| 0x12 | 除以零 |
| 0x21 | 无效 enum 值 |
| 0x22 | 存储槽访问超界 |
| 0x31 | 空数组 pop |
| 0x32 | 数组访问越界 |
| 0x41 | 内存分配过大 |
| 0x51 | 内部函数调用失败 |

## 5. 代码拆解

### 完整示例：Try-Catch 各种场景

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error CustomPanic(uint256 code);

// 会失败的合约
contract FailingContract {
    uint256 public value;

    constructor(uint256 _value) {
        if (_value == 0) revert("Zero value not allowed");
        if (_value == 1) assert(false); // Panic 0x01
        value = _value;
    }

    function setValue(uint256 _value) external {
        if (_value == 0) revert("Zero value");
        if (_value == type(uint256).max) assert(false);
        value = _value;
    }
}

// 调用方
contract TryCatchDemo {
    event Success(uint256 value);
    event CustomError(string reason);
    event PanicError(bytes data);

    function createWithCatch(uint256 _value) external returns (bool) {
        try new FailingContract(_value) returns (FailingContract c) {
            emit Success(c.value());
            return true;
        } catch Error(string memory reason) {
            emit CustomError(reason);
            return false;
        } catch (bytes memory rawData) {
            emit PanicError(rawData);
            return false;
        }
    }

    function callWithCatch(address _target, uint256 _value) external returns (bool) {
        try FailingContract(_target).setValue(_value) {
            return true;
        } catch Error(string memory reason) {
            emit CustomError(reason);
            return false;
        } catch (bytes memory) {
            return false;
        }
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/19_TryCatch.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract TestContract {
    uint256 public value;

    constructor(uint256 _value) {
        if (_value == 0) revert("Zero not allowed");
        if (_value == 1) assert(false);
        value = _value;
    }

    function setValue(uint256 _value) external {
        if (_value == 0) revert("Zero not allowed");
        if (_value == type(uint256).max) assert(false);
        value = _value;
    }
}

contract TryCatchDemo {
    event Log(string message);
    event PanicLog(bytes data);

    function createContract(uint256 _value) external returns (bool success, uint256 result) {
        try new TestContract(_value) returns (TestContract c) {
            success = true;
            result = c.value();
        } catch Error(string memory reason) {
            emit Log(reason);
            success = false;
            result = 0;
        } catch (bytes memory rawData) {
            emit PanicLog(rawData);
            success = false;
            result = 0;
        }
    }

    function callContract(address _target, uint256 _value) external returns (bool) {
        try TestContract(_target).setValue(_value) {
            return true;
        } catch Error(string memory reason) {
            emit Log(reason);
            return false;
        } catch (bytes memory rawData) {
            emit PanicLog(rawData);
            return false;
        }
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
cat > test/19_TryCatch.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/19_TryCatch.sol";

contract TryCatchDemoTest is Test {
    TryCatchDemo public demo;
    TestContract public testContract;

    function setUp() public {
        demo = new TryCatchDemo();
    }

    function testCreateSuccess() public {
        (bool success, uint256 result) = demo.createContract(42);
        assertTrue(success);
        assertEq(result, 42);
    }

    function testCreateZeroReverts() public {
        (bool success, uint256 result) = demo.createContract(0);
        assertFalse(success);
        assertEq(result, 0);
    }

    function testCreateOnePanics() public {
        (bool success, uint256 result) = demo.createContract(1);
        assertFalse(success);
        assertEq(result, 0);
    }

    function testCallSuccess() public {
        testContract = new TestContract(10);
        bool ok = demo.callContract(address(testContract), 99);
        assertTrue(ok);
        assertEq(testContract.value(), 99);
    }

    function testCallZeroReverts() public {
        testContract = new TestContract(10);
        bool ok = demo.callContract(address(testContract), 0);
        assertFalse(ok);
        // value 保持原值 10
        assertEq(testContract.value(), 10);
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

### 错误 1：Try-Catch 捕获不到 assert 失败

- **常见原因**：assert 失败产生 Panic，要用 `catch (bytes memory)` 捕获，不是 `catch Error`
- **解决步骤**：确认 assert 失败走 `catch (bytes memory)` 分支，不是 `catch Error`
- **验证方式**：`forge test` 中覆盖 assert 失败场景

### 错误 2：catch 捕获顺序错误

- **常见原因**：把 `catch Error` 放在 `catch (bytes memory)` 后面，导致 Error 永远匹配不到
- **解决步骤**：确认 catch 顺序是：
  1. `catch Error(string memory reason)` — require/revert("reason")
  2. `catch (bytes memory rawData)` — assert/Panic/未知错误
- **验证方式**：`forge test` 覆盖各种错误类型

### 错误 3：Try-Catch 捕获不了 view 函数中的 require

- **常见原因**：view 函数不产生交易，只是本地调用，不会触发 revert 的完整流程
- **解决步骤**：如果要在 view 函数中验证，用 call 方式触发而不是直接调用
- **验证方式**：测试中确认 view 函数行为符合预期

## 9. 本节总结

- **Try-Catch** = 捕获外部调用中的异常，防止整个交易 revert
- **catch Error(string)** = 捕获 require/revert("reason") 错误
- **catch (bytes memory)** = 捕获 assert 产生的 Panic 错误
- **try new Contract()** = 捕获合约创建时的异常
- **try Interface(target).func()** = 捕获外部合约调用时的异常
- **Panic 代码**：assert 失败时 rawData 包含 Panic(uint256) 编码
- **注意**：catch 顺序很重要，`catch Error` 必须在 `catch (bytes)` 前面

## 10. 课后练习

### 练习 1
写一个 `OracleContract`，包含：
- `address public dataFeed`
- `function setDataFeed(address _dataFeed) external`
- `function getLatestPrice() external returns (uint256 price)` — 用 try-catch 调用 dataFeed 的 `getPrice()` 函数
- 如果调用成功，返回价格；如果失败，返回 0
- 写测试：
  1. 正常合约返回 100
  2. 合约 revert 时返回 0

### 练习 2
写一个 `FactoryWithTryCatch`，包含：
- `function createToken(string memory _name, uint256 _initialSupply) external returns (address tokenAddr, bool success)`
- 如果 token 构造函数 revert（比如 _initialSupply == 0 被拒绝），catch 后返回 (address(0), false)
- 如果成功，返回 (新合约地址, true)
- 写测试覆盖：成功创建、普通 revert、Panic 等场景

## 11. 官方参考

- [Try-Catch](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#try-catch)
- [Error 与 Panic](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#error-handling)
- [Panic 错误代码](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#panic-via-assert)