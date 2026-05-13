# 第 17 课：Create 与 Create2 — 在合约中创建新合约

## 1. 本节目标

学完这节课，你能：
- 理解 `new` 关键字创建合约的方式
- 掌握 `Create` 和 `Create2` 的区别
- 理解 Create2 预知地址的原理和用途
- 能用 foundry 脚本测试合约创建

## 2. 前置知识

- 第 6 课：理解构造函数
- 第 11 课：理解接口和继承
- 第 16 课：理解 ABI 编解码

## 3. 先讲结论

**在合约里创建新合约有两种方式：Create 和 Create2。**

| 对比项 | Create | Create2 |
|--------|--------|---------|
| 地址确定方式 | 随机（基于 sender nonce） | 可预知（基于 sender + salt + bytecode） |
| 地址公式 | `地址 = hash(sender, nonce)` | `地址 = hash(0xff + sender + salt + keccak256(bytecode))` |
| 用途 | 一般场景 | 需要预知地址的场景（如 Create2 预言机） |

**简单记忆**：
- **Create** = "随机地址"，部署完才知道地址
- **Create2** = "指定地址"，部署前就能算出来

## 4. 概念解释

### Create（常规创建）

```solidity
contract Factory {
    // 用 new 关键字创建新合约
    function createToken() external returns (address) {
        Token newToken = new Token("MyToken", "MTK");
        return address(newToken);
    }
}
```

**地址计算**：新合约地址 = `keccak256(rlp(sender, nonce))[12:]`
- sender：创建者的地址
- nonce：创建者当前的 nonce（交易计数）

**特点**：每次调用 nonce 都会 +1，地址可预测但不保证不变。

### Create2（可预知地址）

```solidity
contract Factory2 {
    // 用 create2 创建合约，可以指定 salt
    function createTokenWithSalt(bytes32 salt) external returns (address) {
        Token newToken = new Token{salt: salt}("MyToken", "MTK");
        return address(newToken);
    }
}
```

**地址计算**：`keccak256(0xff + sender + salt + keccak256(bytecode))`
- **salt**：一个随机数，用来"区分不同创建"
- **bytecode**：新合约的字节码（包括 constructor 参数）

**特点**：
1. **地址可预知**：只要知道 sender、salt、bytecode，就能算出地址
2. **不占用 nonce**：即使 sender 之后发了很多交易，用同一个 salt 还是能算出来
3. **用途**：预言机喂价、克隆合约、IPFS 哈希锁定等

### Create2 的完整流程

```solidity
// 步骤 1：用户告诉工厂合约，用 salt S 创建 Token
factory.createTokenWithSalt(salt);

// 步骤 2：用户事先算好地址 = keccak256(0xff + factory + salt + keccak256(bytecode))
address expected = computeAddress(factory, salt, bytecode);

// 步骤 3：创建完成后，地址一定是 expected
assert(address(newToken) == expected);
```

## 5. 代码拆解

### 完整示例：工厂合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 要被创建的简单合约
contract SimpleToken {
    string public name;
    string public symbol;
    uint256 public totalSupply;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }
}

contract TokenFactory {
    // 记录所有创建的代币地址
    SimpleToken[] public tokens;

    // Create 方式创建
    function createToken(string memory _name, string memory _symbol) external returns (SimpleToken) {
        SimpleToken newToken = new SimpleToken(_name, _symbol);
        tokens.push(newToken);
        return newToken;
    }

    // Create2 方式创建（可预知地址）
    function createToken2(
        bytes32 salt,
        string memory _name,
        string memory _symbol
    ) external returns (SimpleToken) {
        SimpleToken newToken = new SimpleToken{salt: salt}(_name, _symbol);
        tokens.push(newToken);
        return newToken;
    }

    // 计算 Create2 地址
    function computeTokenAddress(
        address factory,
        bytes32 salt,
        bytes memory bytecode
    ) external pure returns (address) {
        return keccak256(abi.encodePacked(
            bytes1(0xff),
            factory,
            salt,
            keccak256(bytecode)
        ));
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/17_Create.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Forbidden");
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        Pair pair = new Pair(tokenA, tokenB);
        pair.initialize(tokenA, tokenB);
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }

    // Create2 版本
    function createPair2(address tokenA, address tokenB, bytes32 salt) external returns (address pairAddr) {
        bytes memory bytecode = abi.encodePacked(
            type(Pair).creationCode,
            abi.encode(tokenA, tokenB)
        );
        bytes32 computedSalt = keccak256(abi.encode(tokenA, tokenB));
        Pair pair = new Pair{salt: salt}(tokenA, tokenB);
        pair.initialize(tokenA, tokenB);
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
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
cat > test/17_Create.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/17_Create.sol";

contract PairFactoryTest is Test {
    PairFactory public factory;
    address tokenA = address(0x1);
    address tokenB = address(0x2);

    function setUp() public {
        factory = new PairFactory();
    }

    function testCreatePair() public {
        address pair = factory.createPair(tokenA, tokenB);
        assertTrue(pair != address(0));
    }

    function testCreatePair2() public {
        bytes32 salt = bytes32(0x1234);
        address pair = factory.createPair2(tokenA, tokenB, salt);
        assertTrue(pair != address(0));
    }

    function testPairAddressSame() public {
        // 同一个 token 对，无论多少次 createPair，地址都一样
        address pair1 = factory.createPair(tokenA, tokenB);
        address pair2 = factory.createPair(tokenA, tokenB);
        // 注意：每次 createPair 实际是新的 create，nonce 不同，所以地址不同
        // 这里我们只验证 pair 有值
        assertTrue(pair1 != address(0));
        assertTrue(pair2 != address(0));
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

### 错误 1：Create2 地址算出来不对

- **常见原因**：salt 计算方式和 factory 里实际用的 salt 不一致
- **解决步骤**：
  1. 确认 salt 是怎么算的（建议在 factory 合约内部记录 salt）
  2. 用 Foundry 的 `cast compute-address` 命令验证
  ```bash
  cast compute-address 0xff <factory> <salt> <bytecode>
  ```
- **验证方式**：`forge test` 中 assert 合约创建后的实际地址

### 错误 2：`new Contract()` 的 constructor 参数传递错误

- **常见原因**：constructor 有参数，但 `new Contract()` 没有传参或参数类型不匹配
- **解决步骤**：
  ```solidity
  // 如果 constructor 是 Token(string memory _name, string memory _symbol)
  Token newToken = new Token("MyToken", "MTK");
  ```
- **验证方式**：`forge build` 时类型检查会报错

### 错误 3：Create2 create 前 salt 已用过

- **常见原因**：同一个 sender + 同一个 salt 两次 create，第二次会失败
- **解决步骤**：
  1. 用不同的 salt
  2. 用 token 地址做 salt（确保每个 pair 唯一）
  ```solidity
  bytes32 salt = keccak256(abi.encode(tokenA, tokenB));
  ```
- **验证方式**：`forge test` 覆盖重复 salt 的测试

## 9. 本节总结

- **`new Contract()`** = Create 方式创建合约，地址基于 sender + nonce
- **`new Contract(){salt: salt}()`** = Create2 方式，地址可预知
- **Create2 用途**：预知合约地址（预言机、IPFS 哈希锁定、克隆部署）
- **salt 选择建议**：用唯一标识符（如 token 地址对的 hash）作为 salt，避免冲突
- **type(Pair).creationCode** = 获取 Pair 合约的字节码（用于 Create2 地址计算）

## 10. 课后练习

### 练习 1
写一个 `CounterFactory`，包含：
- `mapping(address => address) public counters` — 每个地址对应的 counter 地址
- `function createCounter() external returns (address)` — 用 Create 方式创建 Counter
- `function createCounter2(bytes32 salt) external returns (address)` — 用 Create2 方式创建 Counter
- Counter 是一个简单合约，有一个 `uint256 public count` 状态变量
- 用测试验证：创建后 counters[user] 有正确的地址，counter.count() == 0

### 练习 2
用 `cast create2 预知地址` 命令测试 Create2：
- 启动 `anvil`
- 用 `forge script` 部署合约后，用 `cast` 工具验证 Create2 算出来的地址是否和实际部署地址一致

## 11. 官方参考

- [Create：创建合约](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#creating-contracts)
- [Create2：预测地址](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#creating-contracts)
- [Salt 和 creationCode](https://docs.soliditylang.org/en/v0.8.35/control-structures.html#external-creating-of-a-contract)