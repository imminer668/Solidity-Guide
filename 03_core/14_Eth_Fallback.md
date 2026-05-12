# 第 14 课：ETH 收发与 fallback

## 1. 本节目标

学完这节课，你能：
- 理解以太坊合约接收 ETH 的两种方式（receive / fallback）
- 掌握三种发送 ETH 的方式（transfer / send / call），理解为什么 `call` 是推荐方式
- 能写一个可接收 ETH 的合约
- 能安全地发送 ETH 并处理返回值

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 12 课：理解 modifier 和权限控制

## 3. 先讲结论

**ETH 收发是以太坊合约最重要的交互之一。**

**接收 ETH**：
- 合约必须实现 `receive()` 或 `fallback()`（或两者都有）
- `receive()` 只在 **msg.data 为空** 时触发（简单转账场景）
- `fallback()` 在 **msg.data 非空** 或 **receive 不存在** 时触发

**发送 ETH**（三种方式）：

| 方式 | 推荐度 | 原因 |
|------|--------|------|
| `.call{value: ...}("")` | ✅ **推荐** | 最灵活，gas 充足时成功 |
| `.transfer()` | ⚠️ 不推荐 | 固定 2300 gas，低 gas 时易失败 |
| `.send()` | ❌ 不推荐 | 固定 2300 gas，返回布尔需检查 |

**安全发送 ETH 的标准写法**：
```solidity
(bool success, ) = payable(_to).call{value: amount}("");
require(success, "Transfer failed");
```

## 4. 概念解释

### receive 函数

```solidity
contract ReceiveDemo {
    receive() external payable {
        // 收到 ETH 时触发（msg.data 为空）
    }
}
```

**触发条件**：
- 转账时 msg.data 是空的
- 合约有 receive 函数
- 合约可以接收 ETH（有余额）

### fallback 函数

```solidity
contract FallbackDemo {
    fallback() external payable {
        // 收到 ETH + msg.data 非空，或 receive 不存在时触发
    }
}
```

**两种情况**：
1. 收到 ETH + msg.data 非空 → 触发 fallback
2. receive 不存在 + 收到 ETH → 触发 fallback

### receive 与 fallback 的触发流程

```
收到 ETH + msg.data
       ↓
  msg.data 为空？──是──→ receive() 存在？──是──→ receive()
       ↓否                      ↓否
  fallback()               fallback()
```

### 发送 ETH 的三种方式

#### 方式 1：transfer（不推荐）

```solidity
payable(_to).transfer(msg.value);
```

- **固定 2300 gas**：只够基本的接收操作
- **失败会 revert**：合约无法接收时自动 revert
- **问题**：如果接收方合约的 fallback 逻辑超过 2300 gas，转账失败

#### 方式 2：send（不推荐）

```solidity
bool success = payable(_to).send(msg.value);
require(success, "Send failed");
```

- **固定 2300 gas**：和 transfer 一样
- **返回布尔**：需要手动检查返回值
- **问题**：gas 不足时 success 返回 false，但不会 revert

#### 方式 3：call（推荐）

```solidity
(bool success, bytes memory data) = payable(_to).call{value: msg.value}("");
require(success, "Transfer failed");
```

- **无 gas 限制**：调用方可以指定任意 gas（取决于区块 gas limit）
- **返回 (success, data)**：需要检查 success
- **推荐原因**：最灵活可靠，合约逻辑再复杂也能转账成功

### 为什么要检查返回值

```solidity
// transfer 和 send 在 v0.8.x 会自动 revert，但 call 需要手动检查
(bool success, ) = payable(_to).call{value: amount}("");
require(success, "Transfer failed");
```

**注意**：v0.8.4 之前 transfer/send 不会自动 revert，v0.8.4 后 behavior 有变化，但建议统一使用 `call` 并手动检查返回值。

## 5. 代码拆解

### 完整示例：可存取的合约钱包

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EthWallet {
    address public owner;
    uint256 public balance;

    // 收到 ETH 时触发（msg.data 为空）
    receive() external payable {
        balance += msg.value;
    }

    // 后备函数（msg.data 非空时触发）
    fallback() external payable {
        balance += msg.value;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    // 提取所有 ETH（仅 owner）
    function withdrawAll() external onlyOwner {
        uint256 amount = balance;
        balance = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 指定金额提取（仅 owner）
    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    // 合约余额查询
    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/14_EthWallet.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EthWallet {
    address public owner;
    uint256 public balance;

    receive() external payable {
        balance += msg.value;
    }

    fallback() external payable {
        balance += msg.value;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = balance;
        balance = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
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
cat > test/14_EthWallet.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/14_EthWallet.sol";

contract EthWalletTest is Test {
    EthWallet public wallet;
    address owner = address(this);
    address recipient = address(0x1);

    function setUp() public {
        wallet = new EthWallet();
    }

    function testReceiveEth() public {
        (bool success,) = address(wallet).call{value: 1 ether}("");
        require(success);
        assertEq(wallet.balance(), 1 ether);
    }

    function testWithdraw() public {
        // 先存钱
        (bool success,) = address(wallet).call{value: 2 ether}("");
        require(success);

        // 再取钱
        wallet.withdraw(1 ether);
        assertEq(wallet.balance(), 1 ether);
    }

    function testOnlyOwnerCanWithdraw() public {
        (bool success,) = address(wallet).call{value: 1 ether}("");
        require(success);

        // 切换到非 owner
        vm.prank(recipient);
        vm.expectRevert("Not owner");
        wallet.withdraw(0.5 ether);
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
- `forge test` 3 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：向合约转账失败，报 `Transfer failed`

- **常见原因**：接收方合约没有 receive/fallback 或 payable 函数，或者 gas 不足
- **解决步骤**：
  1. 确认接收方合约实现了 `receive() external payable`
  2. 使用 `.call{value: ...}("")` 而非 `.transfer()`
  3. 增加调用时的 gas（`anvil` 默认区块 gas 很大，通常够用）
- **验证方式**：`forge test` 中直接测试转账成功

### 错误 2：receive 函数不存在导致合约无法收 ETH

- **常见原因**：合约里只定义了 `fallback()` 但没有 `receive()`，当 msg.data 为空时会触发 fallback（fallback 有 `payable` 才能收 ETH）
- **解决步骤**：如果合约要收 ETH，必须确保：
  - 要么有 `receive() external payable`
  - 要么有 `fallback() external payable`
  - 两者至少有一个
- **验证方式**：`forge test` 向合约发送 ETH 并确认余额增加

### 错误 3：withdraw 时 balance 已减但 ETH 没到账

- **常见原因**：`.call{value: ...}` 返回 success 为 false（接收方 revert）
- **解决步骤**：
  1. 检查 `require(success, "Transfer failed")` 是否触发
  2. 如果是测试环境，确认 recipient 是 payable 的（`payable(address(0x1))`）
  3. 测试环境中，anvil 的默认账户都能接收 ETH
- **验证方式**：检查 `wallet.balance()` 和 recipient 的 ETH 余额是否一致

## 9. 本节总结

- **receive()**：收到空 msg.data 的 ETH 时触发
- **fallback()**：收到非空 msg.data 的 ETH 时，或 receive 不存在时触发
- **发送 ETH 推荐方式**：`.call{value: ...}("")` + 检查 `success`
- **transfer/send 不推荐**：固定 2300 gas，低 gas 场景容易失败
- **注意**：发送 ETH 前要确认目标地址是 payable 的
- **receive/fallback 必须是 payable**：否则合约无法接收 ETH

## 10. 课后练习

### 练习 1
写一个 `SplitWallet` 合约：
- `address public owner`
- `address public partner1`
- `address public partner2`
- `constructor(address _partner1, address _partner2)` 初始化三人
- `receive() external payable` — 收到 ETH 时自动按 50%/25%/25% 分给 owner/partner1/partner2
- `function getBalances() external view returns (uint256 a, uint256 b, uint256 c)` — 查询三人余额
- 用测试验证：合约收到 1 ETH 后，三个人的 ETH 余额分别增加 0.5/0.25/0.25 ether

### 练习 2
在上面的合约基础上添加：
- `function withdrawMyShare() external` — 让任何人可以提取自己的那一份
- 添加事件 `event Withdrawal(address indexed who, uint256 amount)`
- 在每次提取后 emit 事件
- 写测试验证 withdrawMyShare 正常工作

## 11. 官方参考

- [接收 ETH：fallback 和 receive](https://docs.soliditylang.org/en/v0.8.35/contracts.html#receive-eth-function)
- [地址类型](https://docs.soliditylang.org/en/v0.8.35/types.html#address)
- [调用（Call）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#call)