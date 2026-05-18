# 第 21 课：综合练习 1 — Counter 项目

## 1. 本节目标

学完这节课，你能：
- 从头构建一个完整的 Foundry Solidity 项目
- 实现一个简单的 Counter（计数器）合约，带 Foundry 测试
- 掌握"写合约 → 编译 → 测试 → 部署"完整流程
- 理解 public 状态变量的自动 getter

## 2. 前置知识

- 第 3 课：写第一个合约并完成编译、测试、脚本运行
- 第 6 课：函数的基本结构
- 第 12 课：modifier 和权限控制

## 3. 先讲结论

**Counter 项目是 Solidity 开发的"Hello World"。**

这个项目将实现：
- 一个 `Counter` 合约：存储数字，可以加 1、减 1、归零
- Foundry 测试：验证每个操作的行为
- 部署脚本：在本地链/Anvil 上部署

**学完这课，你应该掌握了 Foundry 项目的标准结构。**

## 4. 合约设计

### Counter 合约规格

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Counter {
    uint256 public count; // 计数器值，public 自动生成 getter
    address public owner; // 所有者地址

    event CountIncremented(uint256 newValue);
    event CountDecremented(uint256 newValue);
    event CountReset();

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function increment() external {
        count++;
        emit CountIncremented(count);
    }

    function decrement() external onlyOwner {
        require(count > 0, "Count is zero");
        count--;
        emit CountDecremented(count);
    }

    function reset() external onlyOwner {
        count = 0;
        emit CountReset();
    }
}
```

### 功能说明

| 函数 | 权限 | 功能 |
|------|------|------|
| `increment()` | anyone | 计数 +1，emit 事件 |
| `decrement()` | only owner | 计数 -1（最低 0） |
| `reset()` | only owner | 归零 |
| `count()` | anyone (auto) | 读取当前值（auto getter） |
| `owner()` | anyone (auto) | 读取 owner 地址 |

## 5. 代码拆解

### 合约代码（src/Counter.sol）

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Counter {
    uint256 public count;
    address public owner;

    event CountIncremented(uint256 newValue);
    event CountDecremented(uint256 newValue);
    event CountReset();

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function increment() external {
        count++;
        emit CountIncremented(count);
    }

    function decrement() external onlyOwner {
        require(count > 0, "Count is zero");
        count--;
        emit CountDecremented(count);
    }

    function reset() external onlyOwner {
        count = 0;
        emit CountReset();
    }
}
```

## 6. 实操步骤

### 步骤 1：创建项目（如果还没有）

```bash
# 如果你已经有第 3 课的项目，可以直接使用那个项目
# 如果没有，用以下命令创建
forge init counter-project --no-git
cd counter-project
```

### 步骤 2：编写合约

```bash
cat > src/Counter.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Counter {
    uint256 public count;
    address public owner;

    event CountIncremented(uint256 newValue);
    event CountDecremented(uint256 newValue);
    event CountReset();

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function increment() external {
        count++;
        emit CountIncremented(count);
    }

    function decrement() external onlyOwner {
        require(count > 0, "Count is zero");
        count--;
        emit CountDecremented(count);
    }

    function reset() external onlyOwner {
        count = 0;
        emit CountReset();
    }
}
EOF
```

### 步骤 3：编译

```bash
forge build
```

### 步骤 4：写测试

```bash
cat > test/Counter.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    address owner = address(this);

    function setUp() public {
        counter = new Counter();
    }

    // 初始值测试
    function testInitialCount() public {
        assertEq(counter.count(), 0);
    }

    function testInitialOwner() public {
        assertEq(counter.owner(), owner);
    }

    // increment 测试
    function testIncrement() public {
        counter.increment();
        assertEq(counter.count(), 1);
    }

    function testMultipleIncrement() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 3);
    }

    // decrement 测试
    function testDecrement() public {
        counter.increment();
        counter.increment();
        vm.prank(owner);
        counter.decrement();
        assertEq(counter.count(), 1);
    }

    function testDecrementAtZero() public {
        vm.prank(owner);
        vm.expectRevert("Count is zero");
        counter.decrement();
    }

    // reset 测试
    function testReset() public {
        counter.increment();
        counter.increment();
        vm.prank(owner);
        counter.reset();
        assertEq(counter.count(), 0);
    }

    // 非 owner 不能 decrement
    function testNonOwnerCannotDecrement() public {
        counter.increment();
        address stranger = address(0x1);
        vm.prank(stranger);
        vm.expectRevert("Not owner");
        counter.decrement();
    }

    // 非 owner 不能 reset
    function testNonOwnerCannotReset() public {
        address stranger = address(0x1);
        vm.prank(stranger);
        vm.expectRevert("Not owner");
        counter.reset();
    }
}
EOF
```

### 步骤 5：运行测试

```bash
forge test
```

### 步骤 6：部署脚本

```bash
cat > script/Counter.s.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Script.sol";
import "src/Counter.sol";

contract CounterScript is Script {
    function run() external {
        vm.startBroadcast();

        Counter counter = new Counter();
        console.log("Counter deployed at:", address(counter));

        vm.stopBroadcast();
    }
}
EOF
```

### 步骤 7：部署到 Anvil

```bash
# 先启动 anvil（另一个终端）
anvil

# 然后运行脚本
forge script script/Counter.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS
- `forge script` 部署成功，显示合约地址

## 8. 常见错误排查

### 错误 1：decrement 时 count 已为 0

- **常见原因**：`require(count > 0)` 保护了边界
- **解决步骤**：测试预期 revert，这是正确行为
- **验证方式**：`testDecrementAtZero` 测试已覆盖

### 错误 2：非 owner 调用 revert

- **常见原因**：`onlyOwner` modifier 保护
- **解决步骤**：用 `vm.prank` 模拟非 owner 调用
- **验证方式**：`testNonOwnerCannotDecrement` 测试已覆盖

## 9. 本节总结

- Counter 项目展示了 Foundry 项目的标准结构：`src/` + `test/` + `script/`
- public 状态变量自动生成 getter，不需要手动写 `function count() external view returns(uint256)`
- modifier 是 Solidity 中控制权限的标准方式
- public 函数任何人都能调用，external + onlyOwner 保护后只有 owner 能调用
- 下一课我们将实现 SimpleBank，需要存款和取款逻辑

## 10. 课后练习

### 练习 1
在 Counter 合约中添加 `function setCount(uint256 _count) external onlyOwner`，允许 owner 直接设置计数器值。

### 练习 2
在 Counter 合约中添加：
- `mapping(address => uint256) public lastIncrementedBy`
- 在 `increment()` 中记录 `lastIncrementedBy[msg.sender] = count`
- 添加 `function getLastIncrementedBy(address _user) external view returns (uint256)`

写测试验证：Alice  increment 3 次，Bob increment 2 次后，lastIncrementedBy 正确。