# 第 9 课：常量与错误处理基础

## 1. 本节目标

学完这节课，你能：
- 理解 constant 和 immutable 的区别和使用场景
- 理解 Solidity 的三种异常处理方式（require / revert / assert）
- 在实际合约中正确选择使用哪种错误处理方式
- 学会使用自定义 error（revert CustomError()）

## 2. 前置知识

- 第 5 课：理解 Solidity 基本类型
- 第 6 课：理解函数的基本结构

## 3. 先讲结论

**常量用于"不变的值"，错误处理用于"拒绝非法操作"。**

- **constant**：编译时就确定的值，运行期间不能改变
- **immutable**：部署时在 constructor 中初始化一次，之后不能改变
- **require / revert / assert**：三种触发异常的方式，gas 消耗不同，适用场景不同

**错误处理优先推荐顺序**：
1. 自定义 error `revert CustomError()` — gas 最省（推荐）
2. `require(condition, "message")` — 简单判断，gas 中等
3. `assert()` — 只用于检查"不可能发生"的不变式

## 4. 概念解释

### constant（编译时常量）

```solidity
contract Constants {
    uint256 public constant MAX_SUPPLY = 10000;
    string public constant TOKEN_NAME = "MyToken";
    bytes32 public constant DOMAIN_HASH = keccak256("EIP712Domain");
}
```

**特点**：
- 必须在声明时初始化，之后不能改变
- 编译时直接替换值，不占用 storage
- **gas 最省**

**使用场景**：最大供应量、代币名称、域名哈希等编译时就已知不变的值。

### immutable（部署时常量）

```solidity
contract Immutable {
    address public immutable OWNER;
    uint256 public immutable CREATION_TIME;

    constructor() {
        OWNER = msg.sender;           // 在 constructor 中初始化
        CREATION_TIME = block.timestamp;
    }
}
```

**特点**：
- 声明时不能初始化，必须在 constructor 中初始化一次
- 初始化后不能改变
- 存储在合约代码中（不是 storage），比普通 storage 变量省 gas

**使用场景**：合约所有者、创建时间等部署时才知道值的场景。

**为什么用 immutable 而不是 constant**：
- 有些值在编译时还不知道（如 `msg.sender`，部署时才知道是谁）
- 这种值必须用 immutable，在 constructor 里初始化

### 三种错误处理方式

#### require（最适合条件检查）

```solidity
function transfer(address to, uint256 amount) external {
    require(amount > 0, "Amount must be positive");         // 条件检查
    require(balance[msg.sender] >= amount, "Insufficient balance");
    // ... 执行转账
}
```

**特点**：
- 第一个参数是条件，条件为 false 时触发 revert
- 第二个参数是错误信息字符串
- 适合"参数校验"和"前置条件检查"
- gas 中等（字符串错误信息会增加 gas 消耗）

#### revert（适合分支判断）

```solidity
function withdraw(uint256 amount) external {
    if (amount > balance[msg.sender]) {
        revert("Insufficient balance"); // 和 require 效果相同，但写法更灵活
    }
    // ... 执行提款
}
```

**特点**：
- 等同于 `require(condition, "message")`，但语法写法更灵活
- 适合在 `if` 分支里显式触发 revert
- gas 消耗和 require 类似

#### assert（只用于检查不变式）

```solidity
function pushNumber(uint256 _num) external {
    numbers.push(_num);
    assert(numbers.length <= MAX_LENGTH); // 理论上永远不应该失败
}
```

**特点**：
- 只用于检查"理论上不可能发生"的情况（如数组越界、状态不一致）
- assert 失败触发的是 Panic 类型错误，不是 Error
- **assert 失败不退还剩余 gas**（0.8.x 版本），所以只用于检查 bug

**assert vs require 的选择标准**：
- `require`：检查用户输入和前置条件（可能因为用户操作而触发）
- `assert`：检查内部不变式（理论上永远不应该失败，如果失败说明代码有 bug）

### 自定义 Error（v0.8.35 推荐）

```solidity
// 定义错误类型（在合约外面）
error InsufficientBalance(uint256 available, uint256 required);
error ZeroAmount();
error Unauthorized();

contract Token {
    mapping(address => uint256) public balance;

    function transfer(address to, uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (balance[msg.sender] < amount) {
            revert InsufficientBalance({
                available: balance[msg.sender],
                required: amount
            });
        }
        balance[msg.sender] -= amount;
        balance[to] += amount;
    }
}
```

**为什么推荐自定义 error**：
1. **gas 更省**：比字符串错误信息小得多
2. **可以带参数**：错误信息可以包含实际值，方便调试
3. **结构化**：比字符串更清晰

**v0.8.35 正确示例**：
```solidity
error InsufficientBalance(address user, uint256 have, uint256 want);
...
revert InsufficientBalance(msg.sender, balance[msg.sender], amount);
```

## 5. 代码拆解

### 综合示例：带错误处理的代币合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error TransferNotOwner();
error TransferToZeroAddress();
error InsufficientBalance(address from, uint256 have, uint256 want);

contract Token {
    string public name = "MyToken";
    string public symbol = "MTK";
    uint8 public decimals = 18;
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 10**18; // 10 亿代币

    uint256 public totalSupply;
    address public immutable deployer; // 部署者地址
    mapping(address => uint256) public balanceOf;
    mapping(address => address) public ownerOf;

    constructor() {
        deployer = msg.sender;
    }

    // 转账
    function transfer(address to, uint256 amount) external {
        if (to == address(0)) {
            revert TransferToZeroAddress();
        }
        if (balanceOf[msg.sender] < amount) {
            revert InsufficientBalance({
                from: msg.sender,
                have: balanceOf[msg.sender],
                want: amount
            });
        }

        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
    }

    // 铸造新代币（仅 deployer 可调用）
    function mint(address to, uint256 amount) external {
        if (msg.sender != deployer) {
            revert Unauthorized();
        }
        totalSupply += amount;
        balanceOf[to] += amount;
    }
}
```

**代码拆解**：
- `MAX_SUPPLY` 是 constant，在编译时确定
- `deployer` 是 immutable，在 constructor 中初始化
- 转账时用自定义 error 检查各种异常
- `Unauthorized()` 是简单错误（无参数），`InsufficientBalance` 是带参数错误

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/09_ConstantsAndErrors.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error InsufficientBalance();
error Unauthorized();
error ZeroAmount();

contract SimpleBank {
    // 常量
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    // 不可变变量
    address public immutable owner;

    // 状态变量
    mapping(address => uint256) public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit too small");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (balance[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance(address account) external view returns (uint256) {
        return balance[account];
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
cat > test/09_ConstantsAndErrors.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/09_ConstantsAndErrors.sol";

contract SimpleBankTest is Test {
    SimpleBank public bank;

    function setUp() public {
        bank = new SimpleBank();
    }

    function testDeposit() public {
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success);
        assertEq(bank.balance(address(this)), 1 ether);
    }

    function testWithdraw() public {
        // 先存钱
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success);

        // 再取钱
        bank.withdraw(1 ether);
        assertEq(bank.balance(address(this)), 1 ether);
    }

    function testZeroAmountRevert() public {
        vm.expectRevert(ZeroAmount.selector);
        bank.withdraw(0);
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

### 错误 1：编译报 `Contract "X" should be marked as abstract`

- **常见原因**：合约里有 `virtual` 函数但没有实现，或者有未实现的接口
- **解决步骤**：确保所有函数都有实现，或者把合约标记为 `abstract`
- **验证方式**：`forge build` 成功

### 错误 2：`require` 字符串占用过多 gas

- **常见原因**：错误信息字符串太长（如 `"Transfer failed because sender does not have sufficient balance"`）
- **解决步骤**：
  1. 改用自定义 error，带参数
  2. 如果必须用 require，缩短字符串长度
- **验证方式**：用 `forge gas快照` 查看 gas 消耗对比

### 错误 3：assert 失败导致交易 revert，但不知道原因

- **常见原因**：assert 通常表示代码 bug，不是用户输入问题
- **解决步骤**：
  1. 检查 assert 前后的状态是否一致
  2. 如果是输入检查，改用 require
  3. 如果是理论上"不应该发生"的情况，assert 是对的
- **验证方式**：添加事件记录 assert 失败前的状态

### 错误 4：immutable 变量在 constructor 外初始化

- **常见原因**：试图在合约内其他函数里给 immutable 变量赋值
- **解决步骤**：immutable 变量只能在 constructor 中初始化
- **验证方式**：`forge build` 阶段就会报编译错误

## 9. 本节总结

- **constant**：编译时确定，不占 storage，gas 最省
- **immutable**：部署时初始化，在 constructor 中赋值
- **require**：适合参数校验和前置条件检查，最常用
- **revert**：和 require 等效，适合分支判断中显式触发
- **assert**：只用于检查不变式，失败说明代码有 bug
- **自定义 error**：`revert CustomError()` 是 v0.8.35 推荐写法，gas 最省，可带参数
- **ETH 发送优先使用 `.call{value:}`** 并检查返回值

## 10. 课后练习

### 练习 1
写一个 `VendingMachine` 合约：
- `uint256 public constant ITEM_PRICE = 0.01 ether`
- `address public immutable owner`
- `mapping(address => uint256) public inventory`
- `constructor(address _owner, uint256 initialInventory)` 初始化 owner 和库存
- `function buy() external payable` — 发送 ETH 购买商品（msg.value 必须等于 ITEM_PRICE，库存必须大于 0），成功后 inventory[msg.sender]--
- 用测试验证：买一次后 inventory 减少 1

### 练习 2
在上面的合约中添加自定义 error：
- `error NotEnoughInventory()`
- `error IncorrectPayment()`
- `error Unauthorized()`
- 修改 `buy()` 使用自定义 error 替代 require 语句

## 11. 官方参考

- [常量和不可变量（Constants & Immutables）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#constants)
- [错误处理（Error Handling）](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#error-handling)
- [require / revert / assert](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#error-handling)