# 第 12 课：Modifier 与权限控制

## 1. 本节目标

学完这节课，你能：
- 理解 modifier 的用途（函数执行前的"门槛检查"）
- 能编写自定义 modifier
- 理解常见权限控制模式（onlyOwner、require 守卫）
- 能在合约中正确使用 modifier 进行权限控制

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 9 课：理解常量与错误处理

## 3. 先讲结论

**Modifier 是"门槛函数"，写在函数签名后面，用于在函数执行前自动做检查。**

```solidity
function withdraw(uint256 amount) external onlyOwner {
    // 只有 owner 才能执行这个函数
    // modifier 检查在函数体执行之前就完成了
}
```

**为什么用 modifier**：避免每个函数里都重复写 `require(msg.sender == owner, "Not owner")`，用 `onlyOwner` 代替更简洁。

## 4. 概念解释

### Modifier 的基本结构

```solidity
contract OwnerContract {
    address public owner;

    // 定义 modifier：在 _; 之前是检查逻辑
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;  // 继续执行被修饰的函数体
    }

    // 使用 modifier
    function withdraw() external onlyOwner {
        // 只有 owner 才能执行这里
    }
}
```

**分解**：
- `modifier onlyOwner()` — 定义一个叫 onlyOwner 的修饰器
- `require(msg.sender == owner, "Not owner")` — 检查门槛条件，不满足就 revert
- `_;` — "占位符"，代表被修饰函数的函数体会在这里执行

### 多个 Modifier 叠加

```solidity
function sensitiveOperation() external onlyOwner onlyAdmin {
    // 需要同时满足 onlyOwner 和 onlyAdmin
}
```

### Modifier 带参数

```solidity
modifier onlyAfter(uint256 _time) {
    require(block.timestamp >= _time, "Not yet");
    _;
}

// 使用
function claim() external onlyAfter(1234567890) {
    // 只有到达指定时间才能执行
}
```

### Modifier 组合多种检查

```solidity
modifier onlyOwnerAndNotPaused() {
    require(msg.sender == owner, "Not owner");
    require(!paused, "Contract paused");
    _;
}
```

## 5. 代码拆解

### 权限控制完整示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error NotOwner();
error NotAdmin();
error Paused();

contract AccessControl {
    address public owner;
    mapping(address => bool) public admins;
    bool public paused;

    // ===== modifier =====
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert Paused();
        _;
    }

    // ===== 构造函数 =====
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // ===== 权限控制函数 =====
    function addAdmin(address _addr) external onlyOwner {
        admins[_addr] = true;
    }

    function removeAdmin(address _addr) external onlyOwner {
        admins[_addr] = false;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    // ===== 受保护的写入函数 =====
    function protectedWrite(uint256 _value) external onlyAdmin whenNotPaused {
        // 业务逻辑
    }

    // ===== owner 专属函数 =====
    function ownerOnlyFunction() external onlyOwner {
        // 只有 owner 能执行
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/12_Modifier.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error NotOwner();
error NotAdmin();

contract SecureContract {
    address public owner;
    mapping(address => bool) public admins;
    uint256 public storedValue;
    bool public paused;

    // ===== modifier =====
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert("Paused");
        _;
    }

    // ===== constructor =====
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // ===== 管理函数 =====
    function addAdmin(address _addr) external onlyOwner {
        admins[_addr] = true;
    }

    function removeAdmin(address _addr) external onlyOwner {
        admins[_addr] = false;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    // ===== 业务函数 =====
    function setValue(uint256 _value) external onlyAdmin whenNotPaused {
        storedValue = _value;
    }

    function getValue() external view returns (uint256) {
        return storedValue;
    }

    // owner 专属提款函数
    function withdrawAll() external onlyOwner {
        payable(owner).transfer(address(this).balance);
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
cat > test/12_Modifier.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/12_Modifier.sol";

contract SecureContractTest is Test {
    SecureContract public contract_;
    address public owner = address(this);
    address public admin = address(0x1);
    address public stranger = address(0x2);

    function setUp() public {
        contract_ = new SecureContract();
        // 添加 admin
        contract_.addAdmin(admin);
    }

    // 测试：owner 可以设置值
    function testOwnerCanSetValue() public {
        contract_.setValue(100);
        assertEq(contract_.storedValue(), 100);
    }

    // 测试：admin 可以设置值
    function testAdminCanSetValue() public {
        vm.prank(admin); // 模拟 admin 调用
        contract_.setValue(200);
        assertEq(contract_.storedValue(), 200);
    }

    // 测试：stranger 不能设置值
    function testStrangerCannotSetValue() public {
        vm.prank(stranger); // 模拟 stranger 调用
        vm.expectRevert(NotAdmin.selector);
        contract_.setValue(300);
    }

    // 测试：owner 可以添加 admin
    function testOwnerCanAddAdmin() public {
        contract_.addAdmin(stranger);
        assertEq(contract_.admins(stranger), true);
    }

    // 测试：pause 后 admin 无法 setValue
    function testPausedBlocksAdmin() public {
        contract_.pause();
        vm.prank(admin);
        vm.expectRevert("Paused");
        contract_.setValue(400);
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

### 错误 1：modifier 里忘记加 `_;`

- **常见原因**：定义了 modifier 但函数体里忘了加 `_;`，导致被修饰函数永远不执行
- **解决步骤**：确认每个 modifier 的函数体里有 `_;`
  ```solidity
  modifier onlyOwner() {
      require(msg.sender == owner);
      _; // 必须有这行，代表被修饰函数的函数体
  }
  ```
- **验证方式**：`forge test` 确认函数逻辑正常执行

### 错误 2：modifier 检查失败但函数还是执行了

- **常见原因**：`_;` 位置写在了 `require` 之前，导致函数体先执行了再检查
- **解决步骤**：确认 `require` 或 `if revert` 在 `_;` 之前
  ```solidity
  // 正确顺序：先检查，后执行
  modifier onlyOwner() {
      require(msg.sender == owner, "Not owner");
      _; // 检查通过后，才执行函数体
  }
  ```
- **验证方式**：`forge test` 覆盖权限拒绝的测试用例

### 错误 3：多个 modifier 叠加时顺序问题

- **常见原因**：多个 modifier 叠加时，如果第一个失败，第二个不会执行
- **解决步骤**：注意 modifier 叠加顺序与业务逻辑的关系
- **验证方式**：`forge test` 确认每个 modifier 检查都独立工作

## 9. 本节总结

- **Modifier** = 函数执行前的"门槛检查代码"，用 `modifier name() { require(...); _; }` 定义
- **`_;` 占位符** = 代表被修饰函数的函数体会在检查通过后执行
- **modifier 可以叠加**：一个函数可以用多个 modifier（`external onlyOwner onlyAdmin`）
- **modifier 可以带参数**：`modifier onlyAfter(uint256 _time)`
- **常见模式**：`onlyOwner`、`onlyAdmin`、`whenNotPaused`
- **vm.prank()**：Forge 测试中用于模拟不同地址调用合约

## 10. 课后练习

### 练习 1
写一个 `TimelockContract`，包含：
- `address public owner`
- `uint256 public constant LOCK_TIME = 1 days`
- `mapping(address => uint256) public lockedUntil` — 每个地址的锁定截止时间
- `modifier onlyAfterLock(address _addr)` — 检查当前地址是否已过锁定时间
- `function lock(uint256 _duration) external` — 锁定 msg.sender 自己的代币（设定 `lockedUntil[msg.sender] = block.timestamp + _duration`）
- `function transferLocked(address _to, uint256 _amount) external onlyAfterLock(msg.sender)` — 在锁定时间到达后才能转币
- 用测试验证：锁定 1 天后，才能转币

### 练习 2
写一个 `MultiSigWallet` 合约：
- `address[] public owners`
- `mapping(address => bool) public isOwner`
- `uint256 public required;` — 需要多少个签名
- `modifier onlyOwner()` — 检查是否 owners 之一
- `function submit(address _to, uint256 _value, bytes calldata _data) external onlyOwner` — 提交交易（只是标记，实际执行在别处）
- `function confirm(...)` — 确认交易
- 简化版：只需要实现 owner 管理和 onlyOwner modifier

## 11. 官方参考

- [修饰符（Modifier）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#function-modifiers)
- [可见性（Visibility）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#visibility-and-getters)
- [ Forge 测试工具 vm.prank](https://book.getfoundry.sh/cheatcodes/prank)