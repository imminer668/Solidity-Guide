# 第 7 课：数据存储位置

## 1. 本节目标

学完这节课，你能：
- 理解 Solidity 三种数据存储位置的区别（storage / memory / calldata）
- 在实际编程中正确选择使用哪种数据位置
- 理解为什么 external 函数引用类型参数必须标注数据位置

## 2. 前置知识

- 第 6 课：理解函数的基本结构和可见性

## 3. 先讲结论

**Solidity 有三种数据存储位置，它们决定了变量存在哪里、生命周期多长：**

| 位置 | 存在哪里 | 生命周期 | 费用 |
|------|---------|---------|------|
| `storage` | 区块链上（永久） | 整个合约生命周期 | 最贵（gas 高） |
| `memory` | 内存中（临时） | 仅函数调用期间 | 中等 |
| `calldata` | 调用数据区（只读） | 仅函数调用期间 | 便宜 |

**一个简单的记忆方式**：
- **storage** = "硬盘"，永久存储，贵
- **memory** = "内存"，临时计算，中等
- **calldata** = "只读参数"，external 函数的引用类型参数用它最省 gas

## 4. 概念解释

### storage（永久存储）

```solidity
contract StorageDemo {
    uint256 public storedNumber = 100; // 状态变量，默认存在 storage

    function modify() external {
        storedNumber = 200; // 修改 storage 中的值，永久生效
    }
}
```

**通俗解释**：storage 就像区块链上的"硬盘"。一旦写入，除非主动修改，否则永远存在。状态变量默认存在 storage。

**Gas 特点**：读取和写入 storage 都是 gas 大户，合约里应尽量减少不必要的 storage 操作。

### memory（临时内存）

```solidity
function processString(string memory input) external pure returns (string memory) {
    string memory temp = string.concat(input, " processed");
    return temp;
}
```

**通俗解释**：memory 就像电脑的"内存"。函数调用结束后就消失，不写入区块链。用于处理临时数据。

**使用场景**：
- 函数的引用类型参数（string / array / struct / bytes）
- 函数内部的临时变量

### calldata（只读调用数据）

```solidity
function processCalldata(bytes calldata _data) external pure returns (bytes memory) {
    // _data 是只读的，不能修改
    return _data;
}
```

**通俗解释**：calldata 是"调用参数区"，专门存放传入函数的参数数据。它是只读的，不允许修改。

**使用场景**：
- **external 函数的引用类型参数必须用 calldata**（或者 memory）
- 如果只需要读取参数，不需要修改，用 calldata 更省 gas

### 三种位置的实际对比

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract DataLocationDemo {
    // 状态变量：存储在 storage
    uint256[] public numbers = [1, 2, 3];

    // 读取 storage，返回 memory（复制一份）
    function getNumbers() external view returns (uint256[] memory) {
        return numbers; // 复制 storage 到 memory
    }

    // 以 calldata 作为参数（external 函数必须这样做）
    function sumNumbers(uint256[] calldata _nums) external pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _nums.length; i++) {
            total += _nums[i];
        }
        return total;
    }

    // 以 memory 作为参数（可以在函数内修改，不影响原始数据）
    function doubleNumbers(uint256[] memory _nums) external pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_nums.length);
        for (uint256 i = 0; i < _nums.length; i++) {
            result[i] = _nums[i] * 2;
        }
        return result;
    }
}
```

**关键理解点**：
- `numbers` 是 storage 状态变量
- `sumNumbers` 接收 calldata 参数，只读，gas 最省
- `doubleNumbers` 接收 memory 参数，函数内可以修改副本，不影响原始值
- `getNumbers` 返回 memory 类型，Solidity 自动把 storage 复制到 memory

### 值类型不需要标注数据位置

```solidity
function example(int256 a, uint256 b) external pure returns (int256) {
    // int256 / uint256 是值类型，不需要标注 memory/calldata
    return a + int256(b);
}
```

**原因**：值类型（如 int256、bool、address）无论存在哪里都是完整的一个值，不涉及"指针"或"引用"，因此不需要特别标注。

### 强制要求：external 函数引用类型参数必须标注

```solidity
// 编译错误：external 函数参数是引用类型，必须明确指定数据位置
function processString(string input) external pure { ... }

// 正确写法：明确指定 calldata 或 memory
function processString(string calldata input) external pure { ... }
function processString(string memory input) external pure { ... }
```

**为什么**：`external` 函数的参数传递方式必须是 calldata（或者 memory），编译器需要知道用哪种方式处理。如果不写，Solidity 无法确定。

## 5. 代码拆解

### 理解 storage、memory、calldata 的区别

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract StorageLocation {
    // 状态变量，存在 storage（永久）
    uint256[] public arr;

    constructor() {
        arr.push(1);
        arr.push(2);
        arr.push(3);
    }

    // 读取 storage，返回 memory（复制）
    function readArr() external view returns (uint256[] memory) {
        return arr; // 从 storage 读取并复制到 memory
    }

    // calldata 参数：只读，不允许修改
    function sumCalldata(uint256[] calldata _arr) external pure returns (uint256) {
        uint256 total = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            total += _arr[i];
        }
        return total;
    }

    // memory 参数：可以在函数内修改（不影响 storage 原始数据）
    function doubleMemory(uint256[] memory _arr) external pure returns (uint256[] memory) {
        uint256[] memory result = new uint256[](_arr.length);
        for (uint256 i = 0; i < _arr.length; i++) {
            result[i] = _arr[i] * 2;
        }
        return result;
    }

    // public 函数：参数是 memory 即可（public 函数可以内部调用）
    function processPublic(uint256[] memory _arr) public pure returns (uint256[] memory) {
        return _arr;
    }
}
```

**拆解**：
- `arr` 是 storage 状态变量，任何函数都可以访问
- `sumCalldata` 的 `_arr` 参数是 calldata，只读不修改
- `doubleMemory` 的 `_arr` 参数是 memory，函数内可以修改副本

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/07_DataLocation.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract DataLocation {
    uint256[] public arr;

    constructor() {
        arr.push(10);
        arr.push(20);
        arr.push(30);
    }

    function sumCalldata(uint256[] calldata _arr) external pure returns (uint256 total) {
        total = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            total += _arr[i];
        }
    }

    function doubleMemory(uint256[] memory _arr) external pure returns (uint256[] memory result) {
        result = new uint256[](_arr.length);
        for (uint256 i = 0; i < _arr.length; i++) {
            result[i] = _arr[i] * 2;
        }
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
cat > test/07_DataLocation.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/07_DataLocation.sol";

contract DataLocationTest is Test {
    DataLocation public dl;

    function setUp() public {
        dl = new DataLocation();
    }

    function testSumCalldata() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        assertEq(dl.sumCalldata(arr), 60);
    }

    function testDoubleMemory() public {
        uint256[] memory arr = new uint256[](2);
        arr[0] = 5;
        arr[1] = 15;
        uint256[] memory result = dl.doubleMemory(arr);
        assertEq(result[0], 10);
        assertEq(result[1], 30);
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

### 错误 1：编译报 `Data location must be declared for variable`

- **常见原因**：函数内声明了引用类型（string/array/struct/bytes）的局部变量，但没有指定数据位置
- **解决步骤**：给局部变量加 `memory` 或 `storage`
  ```solidity
  uint256[] memory temp = new uint256[](10); // memory 临时
  ```
- **验证方式**：`forge build` 成功

### 错误 2：编译报 `Location has to be calldata for external function`

- **常见原因**：external 函数参数是引用类型但没有指定 calldata/memory
- **解决步骤**：给 external 函数的引用类型参数加上 `calldata` 或 `memory`
  ```solidity
  // 正确
  function foo(string calldata _s) external pure { ... }
  function bar(string memory _s) external pure { ... }
  ```
- **验证方式**：`forge build` 成功

### 错误 3：修改了 calldata 参数

- **常见原因**：在函数内尝试修改 calldata 参数
  ```solidity
  function foo(uint256[] calldata _arr) external pure {
      _arr[0] = 99; // 编译错误：calldata 是只读的
  }
  ```
- **解决步骤**：如果需要修改，把参数改为 `memory`
  ```solidity
  function foo(uint256[] memory _arr) external pure {
      _arr[0] = 99; // 可以，因为 memory 是可修改的副本
  }
  ```
- **验证方式**：`forge build` 成功

## 9. 本节总结

- `storage`：区块链永久存储，状态变量的家，gas 最贵
- `memory`：临时内存，函数调用期间存在，函数结束消失
- `calldata`：只读参数区，专门用于 external 函数的引用类型参数，gas 最省
- **external 函数的引用类型参数必须标注 calldata 或 memory**
- 值类型（int/uint/bool/address）不需要标注位置
- `public` 函数可以用 memory（因为可能被内部调用），`external` 函数推荐 calldata

## 10. 课后练习

### 练习 1
写一个 `DataLocationPractice` 合约，包含：
- `uint256[] public storageArr` 状态变量
- `function sumArr() external view returns (uint256)` — 用 calldata 接收参数，计算 sum
- `function doubleArr() external view returns (uint256[] memory)` — 用 memory 接收参数，返回翻倍后的数组（不影响原始 storage）

### 练习 2
写一个函数 `mergeString(string memory a, string memory b) external pure returns (string memory)`，将两个字符串拼接。用 Foundry 测试验证 `mergeString("Hello", "World")` 返回 `"HelloWorld"`。

## 11. 官方参考

- [数据位置（Data Location）](https://docs.soliditylang.org/en/v0.8.35/types.html#data-location)
- [Storage / Memory / Calldata](https://docs.soliditylang.org/en/v0.8.35/types.html#data-location)
- [复杂类型的位置标注](https://docs.soliditylang.org/en/v0.8.35/contracts.html#functions)