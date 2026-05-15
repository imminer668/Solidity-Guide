# 第 20 课：常见安全问题与风险提醒

## 1. 本节目标

学完这节课，你能：
- 识别 Solidity 开发中最常见的安全问题
- 理解每种问题的风险和修复方式
- 在实际开发中避免这些常见的坑
- 为后续进阶安全审计打下基础

## 2. 前置知识

- 第 9 课：理解错误处理
- 第 12 课：理解 modifier 和权限控制
- 第 14 课：理解 ETH 发送与接收

## 3. 先讲结论

**安全事故往往不是因为"完全不懂"，而是因为"忽视细节"。**

Solidity 开发中最常见的安全问题：

| 问题 | 风险等级 | 核心原因 |
|------|---------|---------|
| 重入攻击（Reentrancy） | 极高 | 状态更新在外部调用之后 |
| 整数溢出/下溢 | 高（0.8.x 已缓解） | 运算超出类型范围 |
| 未检查返回值 | 高 | call/transfer 返回值未处理 |
| 权限绕过 | 极高 | onlyOwner 等检查被绕过 |
| 价格预言机操纵 | 高 | 依赖可操控的链上价格 |

## 4. 常见安全问题详解

### 问题 1：重入攻击（Reentrancy）

**什么是重入攻击**：调用外部合约时，外部合约可以反过来调用原合约，利用时间差重复提取资金。

**经典例子**：
```solidity
// 有漏洞的提款函数
function withdraw() external {
    uint256 balance = balances[msg.sender];
    (bool success, ) = msg.sender.call{value: balance}(""); // 先转账，后更新状态
    require(success);
    balances[msg.sender] = 0; // 状态更新太晚！
}
```

攻击者可以部署一个合约，在 `call{value:}` 收到 ETH 后，再次调用 `withdraw()`，因为状态还没更新为 0，攻击合约可以反复提取。

**防御方法**：
1. **先更新状态，后外部调用**（Checks-Effects-Interactions 模式）
2. **使用 ReentrancyGuard**（加锁）
3. **使用 pull payment 模式**（让用户自己来取款，而不是主动推送）

```solidity
// 修复后
function withdraw() external {
    uint256 balance = balances[msg.sender];
    require(balance > 0, "Zero balance");
    balances[msg.sender] = 0; // 先更新状态
    (bool success, ) = msg.sender.call{value: balance}("");
    require(success);
}
```

### 问题 2：未检查返回值

**什么是**：使用 `call` 发送 ETH 时，没有检查返回值。

```solidity
// 有风险
address payable to = payable(recipient);
to.transfer(amount); // v0.8.x 会自动 revert，但仍不推荐

// 更好的方式
(bool success, ) = to.call{value: amount}("");
require(success, "Transfer failed");
```

**防御方法**：
1. 总是检查 `call` 的返回值
2. 使用 `require(success)` 明确失败处理

### 问题 3：权限绕过

**什么是**：modifier 或权限检查可以绕过或不完整。

```solidity
// 问题：owner 检查只在 setter 中
function setOwner(address _newOwner) external {
    owner = _newOwner; // 没有 onlyOwner 检查！
}
```

**防御方法**：
1. 每个修改权限的函数都要有对应的 modifier
2. constructor 中的权限初始化要确保安全
3. 使用 OpenZeppelin 的 `Ownable` 等经过审计的库

### 问题 4：整数溢出/下溢（v0.8.x 已缓解）

**什么是**：Solidity 0.8.x 之前，算数运算超出类型范围不会 revert，只会无声地"绕回来"。

```solidity
// v0.8.x 之前的问题
uint256 balance = 0;
balance--; // balance 变成 2^256 - 1（最大值），而不是 -1

// v0.8.x 之后：自动检查溢出/下溢，超出范围直接 revert
uint256 a = type(uint256).max;
a++; // revert
```

**注意**：0.8.x 解决了基础算数的溢出，但如果你用 `unchecked` 块、Yul 或内联汇编，仍然可能出问题。

### 问题 5：价格预言机操纵

**什么是**：合约依赖链上价格（如 Uniswap V2 TWAP），攻击者可以通过大额交易操纵价格。

**场景**：借贷平台用 ` Uniswap pair.getReserves().get(0) / get(1)` 作为价格，攻击者用一笔大额交易抬高或压低价格，然后进行套利。

**防御方法**：
1. 使用 Chainlink 等去中心化预言机
2. 使用时间加权平均价格（TWAP），增加操纵成本
3. 在预言机价格基础上加缓冲（如 2%）

## 5. 代码拆解

### 安全合约示例：重入攻击防护

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract SafeVault {
    mapping(address => uint256) public balances;
    address public owner;

    // 防重入锁
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

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 安全的提款：先更新状态 + 防重入锁
    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "Insufficient balance");

        // 先清零或扣减
        balances[msg.sender] -= amount;

        // 后外部调用
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
```

## 6. 实操步骤

### 步骤 1：创建安全合约示例

```bash
cat > src/20_SecurityExamples.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error Unauthorized();
error ReentrancyDetected();

// 有漏洞的合约（仅用于教学演示）
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 有漏洞的 withdraw（先调用，后更新状态）
    function withdrawBuggy() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Zero balance");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success);
        balances[msg.sender] = 0; // 状态更新太晚！
    }
}

// 安全的合约
contract SafeVault {
    mapping(address => uint256) public balances;
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 安全的 withdraw（先更新状态）
    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount; // 先更新状态
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
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
cat > test/20_SecurityExamples.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/20_SecurityExamples.sol";

contract SecurityTest is Test {
    SafeVault public safeVault;

    function setUp() public {
        safeVault = new SafeVault();
    }

    function testDepositAndWithdraw() public {
        safeVault.deposit{value: 1 ether}();
        assertEq(safeVault.balances(address(this)), 1 ether);

        safeVault.withdraw(1 ether);
        assertEq(safeVault.balances(address(this)), 0);
    }

    function testMultipleWithdrawals() public {
        safeVault.deposit{value: 1 ether}();
        safeVault.withdraw(0.5 ether);
        safeVault.withdraw(0.5 ether);
        assertEq(safeVault.balances(address(this)), 0);
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
- `forge test` 2 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：重入攻击仍然成功

- **常见原因**：虽然用了 modifier，但状态更新仍在外部调用之后
- **解决步骤**：
  1. 确认状态更新在 `_;` 之前（即在外部调用之前）
  2. 确认外部调用在 `_;` 之后
- **验证方式**：用 foundry 的 `forge test -vvv` 查看详细执行流程

### 错误 2：误用 unsafeMath 导致溢出

- **常见原因**：用 `unchecked` 包裹了可能溢出的代码
- **解决步骤**：
  1. 确认 `unchecked` 块里不会真正溢出
  2. 如果可能溢出，用 `require` 先检查
- **验证方式**：`forge test` 覆盖边界值（如 0, 1, max）

### 错误 3：权限检查被绕过

- **常见原因**：某个函数忘记加 onlyOwner
- **解决步骤**：逐个检查所有涉及权限修改的函数
- **验证方式**：`forge test` 中用 `vm.prank` 模拟非 owner 调用

## 9. 本节总结

- **重入攻击**：外部调用期间状态已更新是核心问题，用 Checks-Effects-Interactions 模式 + 锁
- **未检查返回值**：所有 call 都要检查 success
- **权限绕过**：每个修改权限的函数都要有对应 modifier
- **整数溢出**：v0.8.x 已缓解，但 unchecked 和 assembly 仍可能有问题
- **预言机操纵**：使用去中心化预言机 + TWAP + 缓冲
- **最佳实践**：使用 OpenZeppelin 等经过审计的安全库

## 10. 课后练习

### 练习 1
写一个 `SecureBank` 合约，包含：
- `mapping(address => uint256) public balances`
- `function deposit() external payable` — 存款
- `function withdraw(uint256 amount) external` — 取款（防止重入攻击）
- 使用 CEI（Checks-Effects-Interactions）模式
- 写测试验证：
  1. 正常存款取款正常
  2. 存款 1 ETH，取出 0.5 ETH 后，余额正确

### 练习 2
研究 OpenZeppelin 的 `ReentrancyGuard`：
- 查看源码，理解它是如何防止重入的
- 写一个使用 `ReentrancyGuard` 的合约
- 用 foundry 测试验证即使在重入攻击下也无法重复提取

## 11. 官方参考

- [安全建议（官方文档）](https://docs.soliditylang.org/en/v0.8.35/security-considerations.html)
- [重入攻击防护](https://docs.soliditylang.org/en/v0.8.35/security-considerations.html#re-entrancy)
- [OpenZeppelin ReentrancyGuard](https://docs.openzeppelin.com/contracts/4.x/api/utils#ReentrancyGuard)