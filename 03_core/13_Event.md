# 第 13 课：Event 与日志

## 1. 本节目标

学完这节课，你能：
- 理解 Event（事件）的作用：记录在链上交易收据日志中，供外部程序监听
- 能在合约中定义和释放事件
- 能在 Foundry 测试中捕获事件，验证合约行为
- 理解 `indexed` 参数的作用

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 9 课：理解错误处理

## 3. 先讲结论

**Event（事件）是合约向外部世界发"信号"的方式，记录在交易收据里，可被外部程序索引和监听。**

- **Event 不进入合约 storage**：事件数据存在交易收据的日志区，不占用合约 storage
- **外部程序可以监听**：Web3.js / Ethers.js 可以订阅事件，实时知道合约发生了什么
- **调试友好**：在测试中用 `emit Log(...)` 可以追踪函数调用

**简单记忆**：Event = 合约里的"信号弹"，发射到链上，全世界都能接收到。

## 4. 概念解释

### 定义事件

```solidity
contract EventDemo {
    // 定义事件：Transfer(from, to, amount)
    event Transfer(address indexed from, address indexed to, uint256 amount);

    function transfer(address to, uint256 amount) external {
        // ... 转账逻辑
        emit Transfer(msg.sender, to, amount); // 释放事件
    }
}
```

**分解**：
- `event Transfer(...)` — 定义一个叫 Transfer 的事件
- `address indexed from` — `indexed` 关键字表示"可搜索参数"（最多 3 个 indexed）
- `emit Transfer(...)` — 在函数内"释放"事件（发送信号）

### 释放事件

```solidity
emit Transfer(msg.sender, to, amount);
// 或者带命名参数
emit Transfer({from: msg.sender, to: to, amount: amount});
```

**通俗解释**：`emit` 就是"发出一个信号"，让外面监听这个事件的人能收到通知。

### indexed 参数的作用

```solidity
event Transfer(address indexed from, address indexed to, uint256 amount);
```

**为什么用 indexed**：
- **可搜索**：带 indexed 的参数可以被 Etherscan / Web3 事件过滤搜索
- **高效**：EVM 会把 indexed 参数存到 bloom filter 里，快速检索
- **限制**：每个事件最多 3 个 indexed 参数

**无 indexed 参数**：只能获取"全部事件"，不能按条件过滤。

### 常见事件场景

| 场景 | 事件名 | 参数 |
|------|--------|------|
| 转账 | `Transfer` | from, to, amount |
| 授权 | `Approval` | owner, spender, amount |
| 创建订单 | `OrderCreated` | orderId, creator |
| 投票 | `VoteCast` | voter, candidateId |

## 5. 代码拆解

### 事件完整示例：带事件的 ERC20

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EventERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    // 定义事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event Mint(address indexed to, uint256 value);

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
        decimals = 18;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/13_Event.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EventDemo {
    string public name = "EventToken";
    string public symbol = "ETK";
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;

    // 事件定义
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Mint(to, amount);
        emit Transfer(address(0), to, amount);
    }

    function burn(uint256 amount) external {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        totalSupply -= amount;
        balanceOf[msg.sender] -= amount;
        emit Burn(msg.sender, amount);
        emit Transfer(msg.sender, address(0), amount);
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
}
EOF
```

### 步骤 2：编译

```bash
forge build
```

### 步骤 3：写测试（演示如何捕获事件）

```bash
cat > test/13_Event.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/13_Event.sol";

contract EventDemoTest is Test {
    EventDemo public token;

    // 在测试合约中声明事件，以便在 vm.expectEmit 中使用
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function setUp() public {
        token = new EventDemo();
    }

    function testMintEmitsEvents() public {
        // vm.expectEmit 声明：接下来 token.emit 的事件应该和下面这行匹配
        vm.expectEmit(address(token));
        emit Mint(address(this), 1000);
        token.mint(address(this), 1000);

        // 验证余额
        assertEq(token.balanceOf(address(this)), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testTransferEmitsEvent() public {
        token.mint(address(this), 1000);
        address to = address(0x1);

        // 声明期望由 token 发出的 Transfer 事件
        vm.expectEmit(address(token));
        emit Transfer(address(this), to, 300);
        token.transfer(to, 300);

        assertEq(token.balanceOf(address(this)), 700);
        assertEq(token.balanceOf(to), 300);
    }

    function testBurnEmitsEvent() public {
        token.mint(address(this), 1000);
        token.burn(500);

        assertEq(token.balanceOf(address(this)), 500);
        assertEq(token.totalSupply(), 500);
    }
}
EOF
```

**关于 `vm.expectEmit` 的工作原理**：

`vm.expectEmit` 的语义是"声明接下来外部调用发出的事件应该长什么样"。写法是：

```solidity
vm.expectEmit(address(emitterContract)); // 哪个合约会发出这个事件
emit EventName(params);                  // 期望的事件内容
targetContract.someMethod();             // 触发事件的外部调用
```

**拆解**：
- `vm.expectEmit(address(token))` — 声明：接下来事件将由 `token` 合约发出
- `emit Mint(address(this), 1000)` — 定义期望的事件内容（不是真的发出，需要测试合约中已有该事件声明）
- `token.mint(address(this), 1000)` — 实际调用，触发事件

**重要**：测试合约中必须声明事件（`event Mint(...)`），`emit` 语句才能编译通过。这是因为 `emit` 的是测试合约自己声明的事件副本，而不是被测合约的事件本身。

**简单记忆**：`vm.expectEmit` = 期望下一个事件长这样 → 然后去触发它 → 验证实际发出的是否匹配。

**进阶写法（四参数版）**：Foundry 早期版本支持四参数 `vm.expectEmit(checkTopic1, checkTopic2, checkTopic3, emitterAddr)`，可以更细粒度地控制检查哪些 indexed 参数。新手阶段推荐用上面的简洁写法，理解后再用四参数版。


### 步骤 4：运行测试

```bash
forge test
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 3 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：`vm.expectEmit` 没捕获到事件

- **常见原因 1**：emitter 地址写错了（最常犯）。`vm.expectEmit(address(token))` 中填的应该是**实际发出事件的合约地址**，不是测试合约自己的地址。如果事件由 `token` 发出，却写了 `address(this)`，则匹配失败
- **常见原因 2**：`vm.expectEmit` 写在事件释放之后。`vm.expectEmit` 声明的是"接下来期望哪个事件"，必须写在触发语句之前
- **常见原因 3**：`emit Xxx(...)` 声明的期望值和实际事件参数对不上（如 indexed 参数顺序不一致）
- **解决步骤**：
  1. 确认 emitter 地址：如果是合约方法内部 emit，检查哪个合约对象在发事件
  2. 确认顺序：`vm.expectEmit` → `emit ...` → 外部调用，三步顺序不能乱
  3. 确认 `emit` 语句参数和实际事件定义一致（尤其是 indexed 参数）
- **验证方式**：`forge test` 有 FAIL 时，逐项检查以上三点

### 错误 2：事件参数类型不匹配

- **常见原因**：释放 `emit Transfer(a, b, c)` 时参数类型和事件定义不一致
- **解决步骤**：检查事件定义和 emit 语句的参数类型和顺序是否一致
- **验证方式**：`forge build` 阶段会报错

### 错误 3：事件超过 3 个 indexed

- **常见原因**：定义了超过 3 个 indexed 参数
- **解决步骤**：每个事件最多 3 个 indexed 参数，减少 indexed 参数数量
- **验证方式**：`forge build` 阶段会报错

## 9. 本节总结

- **Event** = 合约发出的"链上信号"，记录在交易收据日志中，可被外部程序索引和监听
- `event EventName(params)` 定义事件
- `emit EventName(args)` 释放事件
- `indexed` 参数可搜索，每个事件最多 3 个
- Event 数据不进入合约 storage，而是作为交易日志写入链上收据
- Foundry 测试中用 `vm.expectEmit` 捕获事件，验证合约行为

## 10. 课后练习

### 练习 1
在上一课的 `SecureContract`（第 12 课）中添加事件：
- `event AdminAdded(address indexed admin)`
- `event AdminRemoved(address indexed admin)`
- `event ValueChanged(address indexed setter, uint256 oldValue, uint256 newValue)`
- 在 `addAdmin` 中 emit `AdminAdded`
- 在 `setValue` 中 emit `ValueChanged`（新旧值都要记录）
- 写测试用 `vm.expectEmit` 验证事件正确释放

### 练习 2
设计一个简单的 `EventStore` 合约：
- `struct Article { string title; string content; address author; }`
- `Article[] public articles`
- `event ArticlePublished(uint256 indexed articleId, address indexed author, string title)`
- `function publish(string memory _title, string memory _content) external` — 发布文章，emit 事件
- 写测试验证：发布文章后，用 `vm.prank` 模拟不同用户，确认事件参数正确

## 11. 官方参考

- [事件（Events）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#events)
- [Indexed 参数](https://docs.soliditylang.org/en/v0.8.35/contracts.html#enhanced-types-and-operators)
- [vm.expectEmit（Foundry 官方）](https://book.getfoundry.sh/cheatcodes/expect-emit)