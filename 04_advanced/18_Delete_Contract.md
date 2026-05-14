# 第 18 课：删除合约与 selfdestruct

## 1. 本节目标

学完这节课，你能：
- 理解 `selfdestruct` 的作用和用途
- 理解 EIP-6780 对 selfdestruct 的限制（随 Cancun 硬分叉于 2024-03 在主网上线，Final 状态）
- 知道 EIP-4758 是提议更激进删除指令的方案，目前为 Stagnant 状态，并未被采纳
- 区分"编译器行为"与"链上行为"：`--evm-version` 只决定可用指令集，实际语义由链所处的 EVM 版本决定
- 知道为什么在新合约中不再推荐使用 selfdestruct
- 能识别旧教程中 selfdestruct 的用法并正确更新

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 17 课：理解 Create 与 Create2

## 3. 先讲结论

**`selfdestruct` 是以太坊早期的"删除合约"操作，自 Cancun 硬分叉（2024-03 上线，EIP-6780）起在绝大多数场景下已无"删除"效果。**

**重要变化**（EIP-6780，随 Cancun 上线，Final）：
- 只有在**同一笔交易内通过 CREATE/CREATE2 部署的合约**调用 `selfdestruct`，代码和存储才会被真正删除
- 所有其他情况（包括对早就部署在链上的合约调用）只会**把剩余 ETH 转到指定地址**，合约代码和存储原地保留
- 原本教程中"删除合约"的叫法在 Cancun 之后已不准确

> 注：还有一份更激进的 EIP-4758（"完全废弃 SELFDESTRUCT"），目前是 **Stagnant** 状态，并未被采纳；不要把它和 EIP-6780 混为一谈。

**建议**：在新合约开发中，**不要再把 selfdestruct 作为常规删除手段**，而是作为"紧急提取 ETH"的备选方案。

## 4. 概念解释

### selfdestruct 的历史行为

**Cancun 升级前**（2024-03 之前的所有网络版本）：
```solidity
selfdestruct(payable recipient);
// 效果：合约自毁，所有代码和存储从链上删除，剩余 ETH 转到 recipient
```

**Cancun 升级后**（EIP-6780 已激活）：
```solidity
selfdestruct(payable recipient);
// 效果：仅将合约剩余 ETH 转到 recipient；
// 仅当合约在【同一笔交易内】被 CREATE/CREATE2 部署，代码和存储才会被清空。
```

**注意**：链上行为由**所在链的 EVM 版本**决定（任何已激活 Cancun 的链都受 EIP-6780 约束），与你用什么编译器版本无关。Solidity 编译器的 `--evm-version` 只决定可生成的指令集，并不会改变链上语义。在 0.8.35 中 `selfdestruct` 仍然能编译，但它的运行结果由链决定。

### 为什么旧教程的写法需要更新

**旧教程写法**（`26_DeleteContract`）：
```solidity
// 旧写法：删除合约，把 ETH 转到 owner
function destroy() external onlyOwner {
    selfdestruct(payable(msg.sender));
}
```

**更新后**（Cancun 之后建议的写法）：
```solidity
// 新写法：仅提取 ETH，不声称"删除合约"
function emergencyWithdraw() external onlyOwner {
    payable(msg.sender).transfer(address(this).balance);
}
```

### selfdestruct 的实际可用场景

以下场景仍可能用到 selfdestruct：
1. **升级合约**：在某些升级模式中，用新合约替代旧合约
2. **ETH 提取**：把合约里的 ETH 紧急提取到指定地址
3. **测试环境**：Hardhat / Foundry 测试中清理测试账户

**但要注意**：生产环境中任何依赖 selfdestruct "删除合约"语义的逻辑都已经在 Cancun 之后失效；若后续 EVM 升级（参考 Stagnant 的 EIP-4758 之类提案）进一步收紧，连"转 ETH"这层语义也可能改变，不要在新代码中依赖它。

## 5. 代码拆解

### 紧急 ETH 提取示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract SecureVault {
    address public owner;
    uint256 public balance;

    error NotOwner();
    error NothingToWithdraw();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        balance += msg.value;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 安全提取：使用 call 而非 transfer（因为合约可能需要更多 gas）
    function emergencyWithdraw() external onlyOwner {
        if (address(this).balance == 0) revert NothingToWithdraw();
        uint256 amount = address(this).balance;
        balance = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdraw failed");
    }

    // 替代 selfdestruct 的方式（把 ETH 转到指定地址）
    function migrateETH(address payable _recipient) external onlyOwner {
        require(_recipient != address(0), "Zero address");
        uint256 amount = address(this).balance;
        balance = 0;
        (bool success, ) = _recipient.call{value: amount}("");
        require(success, "Migrate failed");
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约（无 selfdestruct 版本）

```bash
cat > src/18_EmergencyVault.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EmergencyVault {
    address public owner;
    mapping(address => uint256) public balances;

    error NotOwner();
    error NothingToWithdraw();
    error WithdrawFailed();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 紧急提取：owner 提取合约所有 ETH
    function emergencyWithdraw() external onlyOwner {
        if (address(this).balance == 0) revert NothingToWithdraw();
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    // 用户提取自己的存款
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    function getBalance() external view returns (uint256) {
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
cat > test/18_EmergencyVault.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/18_EmergencyVault.sol";

contract EmergencyVaultTest is Test {
    EmergencyVault public vault;
    address owner = address(this);
    address user = address(0x1);

    receive() external payable {}

    function setUp() public {
        vault = new EmergencyVault();
    }

    function testDeposit() public {
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);
        assertEq(vault.getBalance(), 1 ether);
    }

    function testOwnerWithdraw() public {
        (bool success,) = address(vault).call{value: 2 ether}("");
        require(success);

        vault.emergencyWithdraw();
        assertEq(vault.getBalance(), 0);
    }

    function testUserWithdraw() public {
        // user 先充值，才能在 balances[user] 上记账
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        vm.prank(user);
        vault.withdraw();
        assertEq(vault.getBalance(), 0);
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

### 错误 1：旧教程代码里直接用 selfdestruct("删除合约")

- **常见原因**：旧教程写法不适用于 Cancun 之后的 EVM 语义（EIP-6780）
- **解决步骤**：
  1. 把 `selfdestruct(payable(...))` 替换为 `payable(...).call{value: ...}("")`
  2. 删除任何声称"删除合约"的文案
  3. 改用"紧急 ETH 提取"的说法
- **验证方式**：`forge test` 确认替代实现正常工作

### 错误 2：selfdestruct 在测试网/主网表现和预期不同

- **常见原因**：链已激活 Cancun（EIP-6780），selfdestruct 不再删除已有合约
- **解决步骤**：
  1. 在测试中不要依赖 selfdestruct 的"删除"行为
  2. 如果需要清理测试环境，用 Foundry 的 `vm.deal` / `vm.prank` 方式
- **验证方式**：查看目标链的硬分叉版本，确认是否已激活 Cancun

### 错误 3：用户无余额时 withdraw revert

- **常见原因**：没加 `NothingToWithdraw` 检查
- **解决步骤**：在 withdraw 开始时检查 `balances[msg.sender] > 0`
- **验证方式**：`forge test` 覆盖无余额提款场景

## 9. 本节总结

- **`selfdestruct`** 原本是"删除合约 + 转移 ETH"，自 Cancun 升级（EIP-6780，Final）起仅在"同一笔交易内 CREATE 的合约"才会真正被删除
- **新行为**：对早就存在于链上的合约，调用 selfdestruct 只会转走 ETH，代码和存储原地保留
- **`--evm-version` 不决定链上行为**：链上语义由所在链已激活的硬分叉决定，编译器版本无关
- **EIP-4758（更激进的废弃方案）目前是 Stagnant 状态**，不要把它和已生效的 EIP-6780 混为一谈
- **建议**：新合约中不再使用 selfdestruct 作为"删除"手段
- **替代方案**：用 `payable(...).call{value: amount}("")` 提取 ETH
- **旧教程问题**：原 `26_DeleteContract` 章节将 selfdestruct 作为"删除合约"讲解，需要更新

## 10. 课后练习

### 练习 1
写一个 `MigrateContract`，模拟"迁移"场景：
- `address public newContract` — 新合约地址
- `owner` 可以调用 `migrate(address _new)` 设置新合约地址
- `function migrateData(address _new)` — 把当前合约的状态数据通过 call 传给新合约
- `function emergencyWithdrawAll()` — 用 call 方式提取所有 ETH 到 owner
- 写测试验证迁移后新合约收到了数据

### 练习 2
研究 selfdestruct 的历史变化：
- 查询 EIP-6780（Final，Cancun 落地）与 EIP-4758（Stagnant）的内容差异
- 写一段话（200 字以内）解释：
  1. Cancun 升级前 selfdestruct 能做什么
  2. Cancun 升级后（EIP-6780）selfdestruct 发生了什么变化
  3. 为什么这个变化对合约安全有影响

## 11. 官方参考

- [selfdestruct](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#clearing)
- [EIP-6780（Cancun，限制 SELFDESTRUCT，Final）](https://eips.ethereum.org/EIPS/eip-6780)
- [EIP-4758（完全废弃 SELFDESTRUCT 的提案，Stagnant，未采纳）](https://eips.ethereum.org/EIPS/eip-4758)