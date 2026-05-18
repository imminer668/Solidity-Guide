# 第 22 课：综合练习 2 — SimpleBank 项目

## 1. 本节目标

学完这节课，你能：
- 实现一个带存取款功能的银行合约
- 掌握 mapping + address 的余额管理
- 实现基本的 ETH 存取逻辑
- 理解重入攻击风险和防护方式

## 2. 前置知识

- 第 9 课：mapping 类型
- 第 14 课：ETH 收发与 fallback
- 第 20 课：常见安全问题与重入防护

## 3. 先讲结论

**SimpleBank 是一个完整的"存取款合约"，展示了：**
- 用户存款：存入 ETH，余额增加
- 用户取款：从合约提取 ETH，余额减少
- 权限控制：只有 owner 可以做某些操作
- 安全防护：CEI 模式 + ReentrancyGuard

## 4. 合约设计

### SimpleBank 合约规格

```solidity
contract SimpleBank {
    address public owner;                    // 银行所有者
    mapping(address => uint256) public balances; // 用户余额

    receive() external payable {           // 接收 ETH
        balances[msg.sender] += msg.value;
    }

    function deposit() external payable {   // 存款
        require(msg.value > 0);
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount);
        balances[msg.sender] -= amount;    // CEI：先更新状态
        (bool success, ) = payable(msg.sender).call{value: amount}(""); // 后外部调用（推荐写法）
        require(success, "Transfer failed");
    }
}
```

### 功能列表

| 函数 | 权限 | 功能 |
|------|------|------|
| `owner()` | anyone (auto) | 读取 owner |
| `balances(addr)` | anyone (auto) | 读取某地址余额 |
| `receive()` | anyone | 直接转 ETH 到合约 |
| `deposit()` | anyone | 存入 ETH |
| `withdraw()` | anyone | 取出 ETH |

## 5. 代码拆解

### 完整合约（含安全防护）

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error ZeroAmount();
error InsufficientBalance();
error TransferFailed();

contract SimpleBank {
    address public owner;
    mapping(address => uint256) public balances;
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    // 直接往合约地址转 ETH 等于存款
    receive() external payable {
        require(msg.value > 0, ZeroAmount());
        balances[msg.sender] += msg.value;
    }

    function deposit() external payable {
        require(msg.value > 0, ZeroAmount());
        balances[msg.sender] += msg.value;
    }

    // CEI + ReentrancyGuard 防护
    function withdraw(uint256 amount) external noReentrancy {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount; // 先更新状态

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/SimpleBank.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error ZeroAmount();
error InsufficientBalance();
error TransferFailed();

contract SimpleBank {
    address public owner;
    mapping(address => uint256) public balances;
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value > 0, ZeroAmount());
        balances[msg.sender] += msg.value;
    }

    function deposit() external payable {
        require(msg.value > 0, ZeroAmount());
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external noReentrancy {
        if (amount == 0) revert ZeroAmount();
        if (balances[msg.sender] < amount) revert InsufficientBalance();

        balances[msg.sender] -= amount;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert TransferFailed();
    }

    function getBalance() external view returns (uint256) {
        return balances[msg.sender];
    }

    function getContractBalance() external view returns (uint256) {
        return address(this).balance;
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
cat > test/SimpleBank.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank public bank;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        bank = new SimpleBank();
    }

    // 初始状态测试
    function testInitialBalance() public {
        assertEq(bank.balances(user1), 0);
        assertEq(bank.getContractBalance(), 0);
    }

    // 存款测试
    function testDeposit() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.getContractBalance(), 1 ether);
    }

    function testDirectTransfer() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success);
        assertEq(bank.balances(user1), 2 ether);
    }

    // 取款测试
    function testWithdraw() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        vm.prank(user1);
        bank.withdraw(0.5 ether);

        assertEq(bank.balances(user1), 0.5 ether);
    }

    // 取款大于存款 revert
    function testWithdrawInsufficient() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        vm.prank(user1);
        vm.expectRevert(InsufficientBalance.selector);
        bank.withdraw(2 ether);
    }

    // 零额存款 revert
    function testZeroDepositRevert() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        vm.expectRevert(ZeroAmount.selector);
        bank.deposit{value: 0}();
    }

    // 零额取款 revert
    function testZeroWithdrawRevert() public {
        vm.prank(user1);
        vm.expectRevert(ZeroAmount.selector);
        bank.withdraw(0);
    }

    // 多用户测试
    function testMultipleUsers() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();

        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.balances(user2), 2 ether);
        assertEq(bank.getContractBalance(), 3 ether);
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
- `forge test` 8 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：存款后立即取款失败

- **常见原因**：`vm.deal()` 给测试账户假 ETH，但实际测试时用的是 `address(this)` 的 ETH
- **解决步骤**：确保 `deposit` 前给 user 账户足够的 ETH（用 `vm.deal`）
- **验证方式**：`testMultipleUsers` 覆盖多用户场景

### 错误 2：直接往合约转 ETH 后 balances 没有增加

- **常见原因**：`receive()` 函数里忘记加 `balances[msg.sender] += msg.value`
- **解决步骤**：检查 `receive()` 和 `deposit()` 逻辑是否一致
- **验证方式**：`testDirectTransfer` 测试已覆盖

### 错误 3：withdraw 时 ETH 没到账

- **常见原因**：`call{value:}` 返回 success = false
- **解决步骤**：检查 `require(success)` 或 `if (!success) revert`
- **验证方式**：Anvil 环境中，EOA 账户通常能成功接收 ETH

## 9. 本节总结

- SimpleBank 展示了 mapping + address 的余额管理模式
- `receive()` 函数让直接转账成为存款方式
- CEI（Checks-Effects-Interactions）+ ReentrancyGuard 是安全标准
- 所有外部调用（ETH 发送）后都要检查返回值
- `vm.deal()` 在 Foundry 测试中用于给测试账户假 ETH

## 10. 课后练习

### 练习 1
在 SimpleBank 中添加：
- `mapping(address => bool) public isBlacklisted`
- `function blacklist(address _user) external onlyOwner` — 把用户列入黑名单
- 修改 `withdraw` 函数，黑名单用户不能取款
- 写测试验证：Alice 存款后被 blacklist，withdraw revert

### 练习 2
在 SimpleBank 中添加**利息功能**：
- `uint256 public constant INTEREST_RATE = 5`（年化 5%）
- `mapping(address => uint256) public lastUpdateTime`
- 在 `deposit()` 中更新 `lastUpdateTime[msg.sender]`
- 在 `withdraw()` 时计算利息并添加到余额
- 简化版：利息 = balance × 5% × (当前时间 - lastUpdateTime) / 365 days

写测试验证：存款 1 ETH，一年后取款能取到约 1.05 ETH。