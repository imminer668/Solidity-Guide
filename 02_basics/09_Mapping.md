# 第 9 课：映射类型 mapping

## 1. 本节目标

学完这节课，你能：
- 理解 mapping 的用途和基本语法
- 能在合约中声明和使用 mapping
- 理解 mapping 的限制（不能遍历、不能返回完整 mapping）
- 理解 mapping 的键名规则和访问方式

## 2. 前置知识

- 第 5 课：理解 Solidity 基本类型
- 第 6 课：理解函数的基本结构

## 3. 先讲结论

**mapping 就像一个"键值对查表"：给你一个键（key），返回一个对应的值（value）。**

类比：
- 现实中的字典：给一个汉字（key），返回它的拼音和释义（value）→ mapping 是"数字字典"
- 以太坊上的账户余额表：给一个地址（key），返回余额（value）

**语法**：
```solidity
mapping(KeyType => ValueType) public mappingName;
```

## 4. 概念解释

### 基本声明

```solidity
// 将 address 映射到 uint256（地址 → 余额）
mapping(address => uint256) public balances;

// 将 uint256 映射到 address（代币ID → 持有人）
mapping(uint256 => address) public owners;

// 将 address 映射到 bool（地址 → 是否为管理员）
mapping(address => bool) public isAdmin;
```

### 访问和修改

```solidity
mapping(address => uint256) public balances;

function deposit() external payable {
    balances[msg.sender] += msg.value; // 存入 msg.sender 的余额
}

function withdraw(uint256 amount) external {
    require(balances[msg.sender] >= amount, "Insufficient balance");
    balances[msg.sender] -= amount; // 从余额中扣除
    payable(msg.sender).transfer(amount);
}

function getBalance(address _addr) external view returns (uint256) {
    return balances[_addr]; // 通过地址读取余额
}
```

**通俗解释**：`balances[msg.sender]` 就像数组下标访问，但 key 是 address 类型而不是整数。

### mapping 的默认值

声明但未赋值的 mapping 键，返回对应类型的零值：

```solidity
mapping(address => uint256) public balances;

function check() external view returns (uint256) {
    return balances[0x123...]; // 从未设置过的地址，返回 0
}
```

### mapping 不能直接返回

```solidity
// 这样写会编译错误
function getBalances() external view returns (mapping(address => uint256)) {
    return balances; // 错误：mapping 不能作为返回值
}
```

如果需要"返回某地址的所有者"，在 mapping 之外额外记录索引：

```solidity
mapping(address => uint256) public balances;
address[] public accountList; // 用数组记录所有地址

function getAllAccounts() external view returns (address[] memory) {
    return accountList;
}
```

### mapping 嵌套

```solidity
// 二维 mapping：address → (代币ID → 余额)
mapping(address => mapping(uint256 => uint256)) public tokenBalances;

// 访问嵌套 mapping
function getTokenBalance(address _owner, uint256 _tokenId) external view returns (uint256) {
    return tokenBalances[_owner][_tokenId];
}
```

**使用场景**：一个用户持有多种代币，每种代币有不同余额。

## 5. 代码拆解

### 代币余额管理示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract TokenBalance {
    string public name = "BalanceToken";
    string public symbol = "BTK";
    uint8 public decimals = 18;

    mapping(address => uint256) public balances;
    uint256 public totalSupply;

    event Transfer(address indexed from, address indexed to, uint256 amount);

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balances[to] += amount;
    }

    function transfer(address to, uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        balances[to] += amount;
        emit Transfer(msg.sender, to, amount);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return balances[_owner];
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/09_Mapping.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract MappingDemo {
    // 地址 → 余额
    mapping(address => uint256) public balances;

    // 地址 → 是否管理员
    mapping(address => bool) public isAdmin;

    // 地址数组，用于遍历（mapping 本身不能遍历）
    address[] public adminList;

    constructor() {
        // 部署者为第一个管理员
        isAdmin[msg.sender] = true;
        adminList.push(msg.sender);
    }

    modifier onlyAdmin() {
        require(isAdmin[msg.sender], "Not admin");
        _;
    }

    function addAdmin(address _addr) external onlyAdmin {
        if (!isAdmin[_addr]) {
            isAdmin[_addr] = true;
            adminList.push(_addr);
        }
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance(address _addr) external view returns (uint256) {
        return balances[_addr];
    }

    function getAdminCount() external view returns (uint256) {
        return adminList.length;
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
cat > test/09_Mapping.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/09_Mapping.sol";

contract MappingDemoTest is Test {
    MappingDemo public demo;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        demo = new MappingDemo();
    }

    function testInitialBalance() public {
        assertEq(demo.getBalance(address(this)), 0);
    }

    function testDeposit() public {
        (bool success,) = address(demo).call{value: 1 ether}("");
        require(success);
        assertEq(demo.getBalance(address(this)), 1 ether);
    }

    function testWithdraw() public {
        // 先存
        (bool success,) = address(demo).call{value: 2 ether}("");
        require(success);
        // 再取
        demo.withdraw(1 ether);
        assertEq(demo.getBalance(address(this)), 1 ether);
    }

    function testDefaultMappingValue() public {
        // 从未操作过的地址，默认返回 0
        assertEq(demo.getBalance(address(0x999)), 0);
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
- `forge test` 4 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：mapping 不能遍历

- **常见原因**：试图在函数里 `for (uint i = 0; i < balances.length; i++)` 遍历 mapping
- **解决步骤**：mapping 本身不能遍历，如果需要遍历，需要额外维护一个数组记录所有 key
  ```solidity
  address[] public allAccounts; // 记录所有操作过的地址
  mapping(address => uint256) public balances;
  ```
- **验证方式**：`forge build` 不报错（说明代码逻辑正确）

### 错误 2：mapping 不能返回

- **常见原因**：试图让函数返回 `mapping(address => uint256)`
- **解决步骤**：如果需要返回某类数据，可以返回数组，或者用 `getter` 函数逐个获取
- **验证方式**：`forge build` 阶段就报错

## 9. 本节总结

- `mapping(keyType => valueType)` 是"键值对查表"，用于高效查找
- `balances[msg.sender]` 类似数组下标，但 key 可以是任意类型
- 未设置的 key 默认返回零值
- **mapping 不能作为返回值，也不能遍历**；如需遍历，额外维护 key 数组
- mapping 可以嵌套：`mapping(address => mapping(uint256 => uint256))`

## 10. 课后练习

### 练习 1
写一个 `VoterRegistry` 合约：
- `mapping(address => bool) public hasVoted` — 记录是否已投票
- `mapping(address => uint256) public voteCounts` — 每个候选人的得票数
- `address[] public candidates` — 候选人列表
- `function addCandidate(address _candidate) external` — 添加候选人
- `function vote(uint256 _candidateIndex) external` — 投票（检查是否已投过，检查候选人是否存在）
- `function getVoteCount(address _candidate) external view returns (uint256)` — 获取候选人得票

### 练习 2
写一个 `StudentRecord` 合约：
- 定义 `struct Score { uint256 math; uint256 english; uint256 chinese; }`
- `mapping(address => Score) public scores`
- `mapping(address => bool) public isRegistered`
- `function register(address _student) external` — 注册学生
- `function setScore(address _student, uint256 _math, uint256 _english, uint256 _chinese) external` — 设置成绩
- `function getTotalScore(address _student) external view returns (uint256)` — 获取总分
- 写测试验证：注册学生、设置成绩、获取总分

## 11. 官方参考

- [映射类型（Mapping）](https://docs.soliditylang.org/en/v0.8.35/types.html#mapping-types)
- [全局变量（Global Variables）](https://docs.soliditylang.org/en/v0.8.35/units-and-global-variables.html)