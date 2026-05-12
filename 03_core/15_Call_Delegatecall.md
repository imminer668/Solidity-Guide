# 第 15 课：合约调用：Call 与 Delegatecall

## 1. 本节目标

学完这节课，你能：
- 理解 `call` 和 `delegatecall` 在"上下文"上的本质区别
- 能用 `call` 调用其他合约的函数
- 能用 `delegatecall` 在当前合约上下文执行另一个地址的代码
- 理解为什么 delegatecall 要求 storage 布局一致

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 11 课：理解接口和 import
- 第 14 课：理解 ETH 发送

## 3. 先讲结论

**Call 和 Delegatecall 的本质区别在于"谁的 storage 被使用"。**

| 对比项 | `call` | `delegatecall` |
|--------|--------|---------------|
| 执行上下文 | 被调用合约的 storage | 调用合约的 storage |
| msg.sender | 保持不变 | 保持不变 |
| msg.value | 传递（发送到目标合约） | 传递（保留当前调用上下文，不发生 ETH 转账） |
| 用途 | 调用其他已有合约 | 代理模式 / 库复用 / 升级合约 |

**简单记忆**：
- `call` = "去别人家公司用别人的桌子办公"
- `delegatecall` = "把别人公司的员工叫来，在自己公司用我们的桌子办公"

## 4. 概念解释

### call 的基本用法

```solidity
// 调用其他合约的函数
(bool success, bytes memory data) = _addr.call(
    abi.encodeWithSignature("setValue(uint256)", 100)
);
require(success, "Call failed");
```

**特点**：在被调用合约的上下文执行，使用被调用合约的 storage。

### delegatecall 的基本用法

```solidity
// 在当前合约上下文执行另一个地址的代码
(bool success, bytes memory data) = _target.delegatecall(
    abi.encodeWithSignature("setValue(uint256)", 100)
);
```

**特点**：在调用合约的上下文执行，使用调用合约的 storage。

**为什么要求 storage 布局一致**：`delegatecall` 执行的是"代码"，但读写的"存储位置"是调用方的。如果两者的 storage 布局不一致，代码会读写出错的数据。

## 5. 代码拆解

### call 示例：调用方和被调用方各用各的 storage

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 可被调用的目标合约
contract TargetContract {
    uint256 public value; // 自己的 storage

    function setValue(uint256 _value) external {
        value = _value; // 修改 TargetContract 自己的 value
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

// 调用方合约
contract CallerContract {
    uint256 public value; // 自己的 storage（和 TargetContract 的 value 不是同一个）

    // 用 call 调用 TargetContract
    function callSetValue(address _target, uint256 _value) external {
        (bool success, ) = _target.call(
            abi.encodeWithSignature("setValue(uint256)", _value)
        );
        require(success, "Call failed");
    }

    // 用 call 调用 getValue
    function callGetValue(address _target) external view returns (uint256) {
        (bool success, bytes memory data) = _target.call(
            abi.encodeWithSignature("getValue()")
        );
        require(success, "Call failed");
        return abi.decode(data, (uint256));
    }
}
```

**关键点**：call 时，TargetContract.setValue 修改的是 TargetContract 自己的 storage，CallerContract 的 value 不受影响。

### delegatecall 示例：代理合约用自己的 storage 执行他人逻辑

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 逻辑合约（只含代码，没有状态）
contract LogicContract {
    uint256 public value; // slot 0

    function setValue(uint256 _value) external {
        value = _value; // 在 delegatecall 中，这写的是 caller 的 storage
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

// 代理合约（自己的 storage，通过 delegatecall 执行 LogicContract 的逻辑）
contract ProxyContract {
    uint256 public value; // slot 0 —— 与 LogicContract 的 slot 0 位置相同

    // 用 delegatecall 执行另一个合约的逻辑，操作的是 ProxyContract 自己的 storage
    function execute(address _target, uint256 _newValue) external {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _newValue)
        );
        require(success, "Delegatecall failed");
    }

    // 读取自己的 value（应该已经被 delegatecall 修改了）
    function readValue() external view returns (uint256) {
        return value;
    }
}
```

**关键对比**：
- 用 `call` 调用 LogicContract.setValue → LogicContract.value = 100
- 用 `delegatecall` 调用 LogicContract.setValue → ProxyContract.value = 100（修改的是调用方 storage）

**这就是 delegatecall 的核心价值**：ProxyContract 没有 setValue 的代码，但通过 delegatecall"借用"了 LogicContract 的代码，同时使用的是自己的 storage。

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/15_CallDemo.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 逻辑合约：只有代码，没有真正的存储（演示用）
contract LogicContract {
    uint256 public value; // slot 0

    function setValue(uint256 _value) external {
        value = _value;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}

// 代理合约：通过 delegatecall 复用 LogicContract 的代码
// 注意：ProxyContract 和 LogicContract 的 storage 布局必须完全一致
contract ProxyContract {
    uint256 public value; // slot 0，必须和 LogicContract 的 slot 0 对齐

    function execute(address _target, uint256 _newValue) external {
        (bool success, ) = _target.delegatecall(
            abi.encodeWithSignature("setValue(uint256)", _newValue)
        );
        require(success, "Delegatecall failed");
    }

    function readValue() external view returns (uint256) {
        return value;
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
cat > test/15_CallDemo.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/15_CallDemo.sol";

contract CallDemoTest is Test {
    LogicContract public logic;
    ProxyContract public proxy;

    function setUp() public {
        logic = new LogicContract();
        proxy = new ProxyContract();
    }

    // ===== call 测试 =====

    function testCallSetValue() public {
        logic.setValue(42);
        assertEq(logic.value(), 42);
    }

    function testCallGetValue() public {
        logic.setValue(99);
        assertEq(logic.getValue(), 99);
    }

    // ===== delegatecall 测试 =====

    // 核心测试：delegatecall 修改的是 proxy 的 storage，不是 logic 的
    function testDelegatecallModifiesProxyStorage() public {
        // 用 proxy 的 execute 函数，delegatecall 调用 logic 的 setValue
        proxy.execute(address(logic), 100);

        // logic 自己的 value 不受影响
        assertEq(logic.value(), 0); // 从未设置过，保持 0

        // proxy 的 value 被修改了（这就是 delegatecall 的效果）
        assertEq(proxy.value(), 100);
    }

    // delegatecall 后 proxy 能读到自己被修改的值
    function testDelegatecallReadAfterModify() public {
        assertEq(proxy.value(), 0); // 初始值

        proxy.execute(address(logic), 200);

        assertEq(proxy.readValue(), 200); // 通过 proxy 的 readValue 读取
        assertEq(proxy.value(), 200);     // 直接读取 proxy.value
    }

    // 验证：直接调用 setValue 和 delegatecall 调用 setValue 结果互不影响
    function testBothContractsSameLayout() public {
        // 直接用 call 设置 logic 的 value（这是普通函数调用，不是 delegatecall）
        logic.setValue(50);
        assertEq(logic.value(), 50);
        assertEq(proxy.value(), 0); // proxy 不受影响

        // 通过 delegatecall 设置 proxy 的 value
        proxy.execute(address(logic), 50);
        assertEq(proxy.value(), 50); // proxy 被修改
        assertEq(logic.value(), 50); // logic 不受影响（仍然是上一步直接调用设置的 50）
    }

    // 对比：call 不修改 caller 的 storage
    function testCallDoesNotModifyCaller() public {
        // 用 call 调用 logic 的 getValue，call 本身不会修改任何 storage
        // 验证 logic.setValue 直接调用不受影响
        logic.setValue(77);
        assertEq(logic.value(), 77);
        assertEq(proxy.value(), 0); // proxy 不受影响
    }
}
EOF
```

### 步骤 4：运行测试

```bash
forge test
```

**成功时你会看到**：
```
Running 6 tests from CallDemoTest
[PASS] testCallSetValue
[PASS] testCallGetValue
[PASS] testDelegatecallModifiesProxyStorage
[PASS] testDelegatecallReadAfterModify
[PASS] testBothContractsSameLayout
[PASS] testCallDoesNotModifyCaller
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 6 个测试全部 PASS

关键验证点：
- `testDelegatecallModifiesProxyStorage` 验证了 delegatecall 修改的是 proxy 的 storage，而非 logic 的
- `testCallDoesNotModifyCaller` 验证了 call 调用不改变 caller 的 storage

## 8. 常见错误排查

### 错误 1：delegatecall 后 storage 值和预期不符

- **常见原因**：调用方和被调用方的 storage 布局不一致
- **解决步骤**：
  1. 确认两个合约的 storage 变量声明顺序和类型完全一致
  2. 如果两个合约是独立开发的，确保 slot 对齐
  3. 常用做法：使用相同的库或结构体来保证布局一致
- **验证方式**：`forge test` 用 assertEq 验证 storage 值是否正确

### 错误 2：call 返回 success=false

- **常见原因**：函数不存在、参数类型不匹配、目标合约 revert
- **解决步骤**：
  1. 用 `require(success, "Call failed")` 捕获错误
  2. 检查函数签名是否正确（`"setValue(uint256)"`）
  3. 确认目标合约确实实现了该函数
- **验证方式**：`forge test` 确认 success=true

### 错误 3：delegatecall 失败后 storage 已经被部分修改

- **常见原因**：delegatecall 执行到一半失败，但 storage 已经部分修改
- **解决步骤**：
  1. delegatecall 是原子操作，要么全部成功，要么全部回滚
  2. 检查被调用函数内部是否有多个 storage 修改操作
- **验证方式**：`forge test` 验证失败场景下 storage 不变

## 9. 本节总结

- **`call`** = 在被调用合约的上下文执行，使用被调用合约的 storage。适合调用已有合约。
- **`delegatecall`** = 在调用合约的上下文执行另一个地址的代码，使用调用合约的 storage。适合代理模式、库复用、升级合约。
- **Storage 布局一致是 delegatecall 的前提**：调用方和被调用方的 storage 变量必须声明顺序和类型完全一致。
- **`call` 返回 `(bool success, bytes memory data)`**，需要检查 success
- **delegatecall 的经典用途**：Proxy 合约借用 Implementation 合约的逻辑，但保持自己的 storage

## 10. 课后练习

### 练习 1
验证 call 和 delegatecall 的行为差异：
1. 部署两个合约：TargetA（含 `uint256 public value`）和 TargetB（含 `uint256 public value`）
2. 用 CallerContract 分别调用 TargetA 和 TargetB 的 `setValue(42)`
3. 用 assertEq 验证：TargetA.value == 42，TargetB.value == 42，CallerContract.value == 0

### 练习 2
设计一个"计数器代理"合约：
- 部署一个 `CounterLogic` 合约（含 `uint256 public count` 和 `function increment() external`）
- 部署一个 `CounterProxy` 合约（也有 `uint256 public count`，slot 布局与 CounterLogic 一致）
- `CounterProxy` 用 delegatecall 调用 `CounterLogic.increment`
- 验证：`CounterLogic.count` 仍为 0，但 `CounterProxy.count` 已变为 1

## 11. 官方参考

- [Call 和 Delegatecall](https://docs.soliditylang.org/en/v0.8.35/contracts.html#call)
- [地址类型方法：call](https://docs.soliditylang.org/en/v0.8.35/types.html#address)
- [代理模式与 delegatecall](https://docs.soliditylang.org/en/v0.8.35/contracts.html#delegatecall)