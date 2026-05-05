# 第 5 课：值类型与默认值

## 1. 本节目标

学完这节课，你能：
- 识别 Solidity 的主要值类型（bool/int/uint/address/bytes1~32/enum）
- 理解每种类型的默认值（零值）是什么
- 能在合约中正确声明和使用各种值类型变量

## 2. 前置知识

- 第 4 课：理解 Solidity 源文件的基本结构（SPDX/pragma/contract）
- 第 2 课：会写基础的 Solidity 合约

## 3. 先讲结论

**Solidity 的值类型就像不同规格的容器，每个容器只装一种固定规格的东西。**

- 布尔只有"真/假"两种值：`true` / `false`
- 整数用来装数字，有带符号（int）或不带符号（uint）之分
- 地址用来装以太坊账户地址
- 字节用来装定长的字节序列
- 枚举用来装有限选项的自定义类型

**所有值类型变量声明后不赋值，默认值都是"零值"：0、false、0x0...**

## 4. 概念解释

### 布尔类型（bool）

```solidity
bool public _bool = true;           // 真
bool public _bool1 = !_bool;        // 取反：false
bool public _bool2 = _bool && _bool1; // 逻辑与：false（真的同时要为假，不可能）
bool public _bool3 = _bool || _bool1;  // 逻辑或：true（真的或者为假，至少一个为真）
bool public _bool4 = _bool == _bool1;  // 相等比较：false
bool public _bool5 = _bool != _bool1;  // 不等比较：true
```

**通俗解释**：布尔就是"开关"，只有两种状态。Solidity 里用于条件判断。

### 整数类型（int / uint）

```solidity
int public _int = -1;                    // 有符号整数，可正可负
uint public _uint = 1;                    // 无符号整数，只能是正数或零
uint256 public _number = 20230601;        // 256 位无符号整数，最大约 1.15 × 10^77
```

**int 与 uint 的区别**：
- `int`（有符号）：可以是负数、零、正数，范围是 `-2^255` ~ `2^255 - 1`
- `uint`（无符号）：只能是零或正数，范围是 `0` ~ `2^256 - 1`

**uint 后面的数字**：表示位数，常用的是 `uint256`（256 位）。`uint` 默认等于 `uint256`。

**整数运算符**：
```solidity
uint256 public a = 10 + 5;   // 加法：15
uint256 public b = 10 - 5;   // 减法：5
uint256 public c = 10 * 5;   // 乘法：50
uint256 public d = 10 / 5;   // 除法：2
uint256 public e = 10 % 3;   // 取余：1
uint256 public f = 2 ** 4;   // 指数：16（2 的 4 次方）
bool public g = 10 > 5;      // 比较：true
```

### 地址类型（address / address payable）

```solidity
address public _addr = 0x7A58c0Be72BE218B41C608b7Fe7C5bB630736C71;
address payable public _addrPayable = payable(_addr); // 可转账地址
uint256 public balance = _addrPayable.balance;       // 查余额
```

**通俗解释**：地址就是以太坊上的"账号"，用 42 位十六进制数表示，以 `0x` 开头。

**address vs address payable**：
- `address`：普通地址，可以存储账户地址、查看余额
- `address payable`：可转账地址，可以查余额，也可以转 ETH 给它
- 两者可以互相转换：`payable(addr)` 把 address 转成 address payable

### 固定字节数组（bytes1 ~ bytes32）

```solidity
bytes32 public _byte32 = "MiniSolidity";
bytes1 public _byte = _byte32[0];
```

**通俗解释**：`bytes1` ~ `bytes32` 是固定长度的字节数组：
- `bytes1` 只能存 1 个字节（0x00 ~ 0xff）
- `bytes32` 只能存 32 个字节
- `"MiniSolidity"` 转成 bytes32 后，会在右侧补零到 32 字节

**与 string 的区别**：
- `string`：可变长度，用于存储文本，通常配合 `abi.encodePacked()` 使用
- `bytes1~32`：固定长度，用于存储原始字节数据，通常用于 gas 优化场景

### 枚举类型（enum）

```solidity
enum ActionSet { Buy, Hold, Sell }

// 创建 enum 变量
ActionSet public action = ActionSet.Buy;

// enum 与 uint 互转
function getActionValue() external view returns (uint) {
    return uint(action); // Buy = 0, Hold = 1, Sell = 2
}
```

**通俗解释**：枚举就是"有限选项列表"，适合用在"状态机"场景。Buy/Hold/Sell 只有这三个选项，不会出现第四个。

### 默认值（零值）

声明但未赋值的值类型变量，默认值如下：

| 类型 | 默认值 | 说明 |
|------|--------|------|
| `bool` | `false` | 布尔默认假 |
| `int` / `uint` | `0` | 整数默认零 |
| `address` | `0x0000000000000000000000000000000000000000` | 地址默认零地址 |
| `bytes1~32` | 全 0x00 | 字节默认全零 |
| `enum` | 第一个枚举值（序号 0） | 枚举默认第一个成员 |

```solidity
bool public defaultBool;        // false
uint256 public defaultUint;    // 0
address public defaultAddr;    // 0x0000000000000000000000000000000000000000
```

**为什么重要**：如果忘记给变量赋值，代码会使用默认值继续运行，可能导致意外行为。

## 5. 代码拆解

### 综合示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract TypesDemo {
    // 布尔
    bool public flag = true;

    // 整数
    int public negative = -10;
    uint public positive = 100;

    // 地址
    address public owner = msg.sender;
    address payable public recipient = payable(msg.sender);

    // 固定字节
    bytes32 public data = "Hello";

    // 枚举：订单状态
    enum OrderStatus { Pending, Confirmed, Shipped, Received }
    OrderStatus public status = OrderStatus.Pending;

    // 默认值演示
    bool public defaultBool;
    uint256 public defaultUint;
    address public defaultAddr;

    // 获取余额
    function getBalance(address _addr) external view returns (uint256) {
        return _addr.balance;
    }

    // 枚举转 uint
    function getStatusValue() external view returns (uint) {
        return uint(status);
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约文件

```bash
cat > src/05_ValueTypes.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ValueTypesDemo {
    bool public flag = true;
    int public negative = -10;
    uint public positive = 100;
    address public owner = msg.sender;
    bytes32 public data = "Hello";
    enum OrderStatus { Pending, Confirmed, Shipped }
    OrderStatus public status = OrderStatus.Pending;

    // 默认值
    bool public defaultBool;
    uint256 public defaultUint;

    function getStatusValue() external view returns (uint) {
        return uint(status);
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
cat > test/05_ValueTypes.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/05_ValueTypes.sol";

contract ValueTypesDemoTest is Test {
    ValueTypesDemo public demo;

    function setUp() public {
        demo = new ValueTypesDemo();
    }

    function testDefaultBool() public {
        assertEq(demo.defaultBool(), false);
    }

    function testDefaultUint() public {
        assertEq(demo.defaultUint(), 0);
    }

    function testStatusValue() public {
        assertEq(demo.getStatusValue(), 0); // Pending = 0
    }

    function testFlag() public {
        assertEq(demo.flag(), true);
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

### 错误 1：编译报 `Type uint8 memory is not implicitly convertible`

- **常见原因**：enum 变量直接赋了超出范围的整数值
- **解决步骤**：enum 只接受定义范围内的成员，如 `OrderStatus.Confirmed`，不能直接写 `5`
- **验证方式**：`forge build` 成功

### 错误 2：地址转账报 `Address: insufficient balance`

- **常见原因**：试图给一个合约地址转 ETH，但那个合约没有 `receive()` 或 `payable` 函数
- **解决步骤**：确认目标地址是可收 ETH 的地址（普通 EOA 或带 receive 的合约）
- **验证方式**：转 ETH 前先查目标地址余额

### 错误 3：整数溢出 / underflow（Solidity 0.8.x 默认检查）

- **常见原因**：在 0.8.x 版本，整数溢出/下溢会导致交易 revert（自动检查）
- **解决步骤**：
  - 如果确实需要溢出行为，用 `unchecked { ... }` 包裹
  - 如果是 bug，检查运算逻辑是否预期可能溢出
- **验证方式**：`forge test` 确认 revert 是预期行为还是 bug

## 9. 本节总结

- Solidity 值类型包括：bool、int/uint、address/address payable、bytes1~32、enum
- 每种类型有明确的用途和取值范围
- 所有值类型默认值都是零值（0/false/0x0...）
- 枚举适合表达有限状态的"选择列表"，默认是第一个成员
- Solidity 0.8.x 会自动检查整数溢出/下溢

## 10. 课后练习

### 练习 1
写一个 `TokenContract`，包含：
- `string public name = "MyToken"`
- `string public symbol = "MTK"`
- `uint256 public totalSupply`
- `address public minter`（谁是发行方）
- `constructor(address _minter)` 初始化 minter
- `function mint(address to, uint256 amount) external` 铸造代币（增加 totalSupply）

### 练习 2
定义一个 `Grade` 枚举，包含 `A / B / C / D / F` 五个等级。写一个函数 `getGradeScore(Grade g) external pure returns (uint)`，返回每个等级对应的分数（A=100, B=80, C=60, D=40, F=20）。写测试验证每个等级返回的分数。

## 11. 官方参考

- [值类型（Value Types）](https://docs.soliditylang.org/en/v0.8.35/types.html#value-types)
- [整型（Integer Types）](https://docs.soliditylang.org/en/v0.8.35/types.html#integers)
- [地址类型（Address）](https://docs.soliditylang.org/en/v0.8.35/types.html#address)
- [枚举（Enum）](https://docs.soliditylang.org/en/v0.8.35/types.html#enums)