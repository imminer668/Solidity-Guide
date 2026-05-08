# 第 11 课：继承、接口、库与 import

## 1. 本节目标

学完这节课，你能：
- 理解 Solidity 的代码复用机制（继承 / 接口 / 库）
- 能在合约中正确使用 `inherit`、`interface`、`library`
- 掌握 `import` 导入其他文件的写法
- 理解 `is`（继承）、`interface`（接口定义）、`library`（工具库）的区别

## 2. 前置知识

- 第 6 课：理解函数和可见性
- 第 8 课：理解结构体

## 3. 先讲结论

**当多个合约需要共用同一段代码时，有三种方式：继承、接口、库。选择哪种取决于你的场景。**

| 方式 | 关键字 | 用途 | 是否占用 storage |
|------|--------|------|----------------|
| 继承 | `is` | 子合约复用父合约的状态变量和函数 | ✅ 占用 |
| 接口 | `interface` | 定义"必须有什么函数"，不实现 | ❌ 不占用 |
| 库 | `library` | 提供工具函数，通过 delegatecall 调用 | ❌ 不占用 |

**简单记忆**：
- **继承** = "复制父类的全部代码过来"
- **接口** = "规定必须实现哪些函数签名"
- **库** = "把工具函数打包，不持有状态"

## 4. 概念解释

### 继承（inheritance）

```solidity
// 父合约
contract Base {
    uint256 public baseValue;

    function setBaseValue(uint256 _value) external {
        baseValue = _value;
    }
}

// 子合约继承 Base
contract Derived is Base {
    uint256 public derivedValue;

    function setDerivedValue(uint256 _value) external {
        derivedValue = _value;
    }
}
```

**通俗解释**：子合约继承了父合约的所有状态变量和函数，相当于把父合约的代码复制到子合约里。

**调用方式**：
```solidity
Derived d = new Derived();
d.setBaseValue(10);      // 调用继承来的函数
d.baseValue();           // 读取继承来的状态变量
```

### 接口（interface）

```solidity
// 定义接口：规定"必须实现 setValue 函数"
interface IToken {
    function setValue(uint256 _value) external;

    function getValue() external view returns (uint256);
}
```

**通俗解释**：接口只定义函数签名（名字 + 参数 + 返回值），不实现具体逻辑。实现接口的合约必须实现这些函数。

**为什么用**：
- 让合约知道"对方有什么函数可以调用"
- 不关心对方怎么实现，只关心接口

**实现接口**：
```solidity
contract Token is IToken {
    uint256 public value;

    function setValue(uint256 _value) external {
        value = _value;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}
```

### 库（library）

```solidity
library Math {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        return a + b;
    }

    function multiply(uint256 a, uint256 b) internal pure returns (uint256) {
        return a * b;
    }
}

contract UseLibrary {
    function calculate(uint256 a, uint256 b) external pure returns (uint256, uint256) {
        return (Math.add(a, b), Math.multiply(a, b));
    }
}
```

**通俗解释**：库是"工具箱"，里面的函数是独立的，不属于任何合约。通过 `Math.add(a, b)` 方式调用。

**注意**：库函数如果修改 storage，需要通过 `using Library for Struct` 语法，或者手动 delegatecall。

### import 导入

```solidity
// 导入本地文件
import { IToken } from "./interfaces/IToken.sol";
import "./Ownable.sol";

// 导入时重命名（解决名字冲突）
import { Token as TokenContract } from "./Token.sol";
```

**另一种写法**（推荐）：
```solidity
// 直接导入，不需要花括号
import "./interfaces/IToken.sol";

// 使用时加前缀
IToken token = IToken(address);
```

### 继承中的 constructor 顺序

```solidity
contract Base {
    uint256 public baseValue;

    constructor(uint256 _value) {
        baseValue = _value;
    }
}

// 子合约继承时，constructor 需要传入参数
contract Derived is Base(100) {
    uint256 public derivedValue;
}
```

**注意**：子合约必须在 `is` 后面直接传参给父合约的 constructor，或者在子合约的 constructor 中显式调用父合约。

## 5. 代码拆解

### 完整示例：ERC20 代币接口继承实现

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 定义 ERC20 接口
interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

// 实现 ERC20
contract SimpleERC20 is IERC20 {
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;

    uint256 public override totalSupply;
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        require(balanceOf[from] >= amount, "Insufficient balance");
        require(allowance[from][msg.sender] >= amount, "Allowance exceeded");
        balanceOf[from] -= amount;
        allowance[from][msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
```

## 6. 实操步骤

### 步骤 1：创建接口文件

```bash
mkdir -p src/interfaces
cat > src/interfaces/IERC20.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
}
EOF
```

### 步骤 2：创建实现合约

```bash
cat > src/11_ERC20.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "./interfaces/IERC20.sol";

contract SimpleERC20 is IERC20 {
    mapping(address => uint256) public balanceOf;
    uint256 public totalSupply;
    string public name;
    string public symbol;

    constructor(string memory _name, string memory _symbol) {
        name = _name;
        symbol = _symbol;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
}
EOF
```

### 步骤 3：编译

```bash
forge build
```

### 步骤 4：写测试

```bash
cat > test/11_ERC20.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/11_ERC20.sol";

contract ERC20Test is Test {
    SimpleERC20 public token;

    function setUp() public {
        token = new SimpleERC20("MyToken", "MTK");
    }

    function testMintAndBalance() public {
        token.mint(address(this), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testTransfer() public {
        token.mint(address(this), 1000);
        token.transfer(address(0x1), 300);
        assertEq(token.balanceOf(address(this)), 700);
        assertEq(token.balanceOf(address(0x1)), 300);
    }
}
EOF
```

### 步骤 5：运行测试

```bash
forge test
```

## 7. 运行结果验证

- `forge build` 成功（编译接口 + 合约）
- `forge test` 2 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：编译报 `Contract "X" should be declared as abstract`

- **常见原因**：合约里有 `override` 但没有实现父合约或接口的所有函数
- **解决步骤**：
  1. 确认接口的所有函数都实现了（名字、参数、返回值必须完全匹配）
  2. 如果暂时无法实现，先把合约标记为 `abstract contract X is IToken`
- **验证方式**：`forge build` 成功

### 错误 2：override 函数签名不匹配

- **常见原因**：override 函数的签名（参数类型、返回值）与父合约/接口定义不一致
- **解决步骤**：检查函数签名是否完全一致，特别是 `memory` / `calldata` 标注
- **验证方式**：`forge build` 成功

### 错误 3：继承时 constructor 参数传递顺序

- **常见原因**：父合约 constructor 有参数，但子合约没有正确传递
- **解决步骤**：
  ```solidity
  // 方式 1：在 is 后直接传参
  contract Derived is Base(100) { ... }

  // 方式 2：在子合约 constructor 中显式调用
  constructor(uint256 _value) Base(_value) { }
  ```
- **验证方式**：`forge test` 通过

### 错误 4：import 文件路径错误

- **常见原因**：import 路径拼写错误或文件不存在
- **解决步骤**：
  1. 确认文件在 `src/` 目录下
  2. 使用相对路径 `./interfaces/IERC20.sol`
  3. Foundry 项目也可以用 `forge-std/` 前缀导入库
- **验证方式**：`forge build` 不报 "File not found"

## 9. 本节总结

- **继承 `is`**：子合约复制父合约的全部代码，共享 storage
- **接口 `interface`**：只定义函数签名，不实现，强制实现类完成所有函数
- **库 `library`**：工具函数集合，不持有状态，通过 `Lib.func()` 调用
- **import**：导入其他 Solidity 文件，支持相对路径和别名
- **override**：`override` 关键字用于重写父合约或接口中的函数
- **event**：ERC20 中用 `emit Transfer(...)` 记录转账事件

## 10. 课后练习

### 练习 1
定义一个 `interface IStorage`，包含：
- `function store(uint256 _value) external`
- `function retrieve() external view returns (uint256)`

然后实现一个 `StorageContract : IStorage`，包含：
- `uint256 public value`
- `store()` 保存值
- `retrieve()` 返回值

用测试验证：存 42，取出来是 42。

### 练习 2
写一个库 `LibraryMath`，包含：
- `function add(uint256 a, uint256 b) external pure returns (uint256)`
- `function multiply(uint256 a, uint256 b) external pure returns (uint256)`
- 在主合约中用 `using LibraryMath for uint256` 调用

## 11. 官方参考

- [继承（Inheritance）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#inheritance)
- [接口（Interface）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#interfaces)
- [库（Library）](https://docs.soliditylang.org/en/v0.8.35/contracts.html#libraries)
- [Import 语句](https://docs.soliditylang.org/en/v0.8.35/layout-of-source-files.html#import)

### 练习 2
参考上面的 SimpleERC20，添加 `allowance` 和 `transferFrom` 功能：
- 实现 `IERC20` 中剩余的 `allowance`、`approve`、`transferFrom` 四个函数
- 用 `transferFrom` 从一个账户转钱给另一个账户（需要先 approve）
- 写测试验证：
  1. Alice mint 1000 代币给自己
  2. Alice approve Bob 可花费 300
  3. Bob 从 Alice 转 200 给 Carol
  4. 验证 Alice 余额 = 800，Bob 余额 = 0，Carol 余额 = 200