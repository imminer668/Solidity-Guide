# 第 16 课：ABI 编解码与 Selector

## 1. 本节目标

学完这节课，你能：
- 理解 ABI 是什么（合约调用数据的编码格式）
- 掌握 `abi.encode` / `abi.decode` / `abi.encodeWithSelector` / `abi.encodeWithSignature` 的用法
- 理解函数选择器（Selector）的概念和计算方式
- 能用 ABI 编码调用合约函数

## 2. 前置知识

- 第 6 课：理解函数的基本结构
- 第 15 课：理解 call 调用

## 3. 先讲结论

**ABI（Application Binary Interface）是合约之间互相调用的"数据协议"。**

当合约 A 调用合约 B 的函数时，数据要按照 ABI 格式编码后才能发送。理解 ABI，才能理解 Selector 和各种 encode 方法的用途。

**核心概念**：
- **Selector（选择器）** = 函数名的 keccak256 哈希的前 4 字节，用于指定调用哪个函数
- **abi.encode** = 把参数打包成字节数组
- **abi.decode** = 把字节数组还原成参数

## 4. 概念解释

### 函数选择器（Selector）

```solidity
// Selector = keccak256("函数签名").前4字节
bytes4 selector = bytes4(keccak256("setValue(uint256)"));
// bytes4(0x3ec37834) — 前 4 字节
```

**为什么用 4 字节**：足够区分数十亿个函数，且节省 gas。

**Solidity 提供了两种计算 Selector 的方式**：
```solidity
// 方式 1：keccak256 取前 4 字节
bytes4 sel = bytes4(keccak256("foo(uint256)"));

// 方式 2：函数属性 .selector
bytes4 sel = this.foo.selector; // 如果合约里有 foo 函数
```

### ABI 编解码函数

#### abi.encode（标准编码）

```solidity
bytes memory encoded = abi.encode(uint256(1), address(0x123));
// 将 1 和地址 0x123 编码为字节数组
```

#### abi.decode（解码）

```solidity
(uint256 a, address b) = abi.decode(encoded, (uint256, address));
// 从字节数组还原出原始值
```

#### abi.encodeWithSignature（带签名编码）

```solidity
bytes memory data = abi.encodeWithSignature("setValue(uint256)", 42);
// 等于: bytes4(keccak256("setValue(uint256)")) + abi.encode(uint256(42))
```

**用途**：直接用函数签名 + 参数，生成完整调用数据。

#### abi.encodeWithSelector（带选择器编码）

```solidity
bytes memory data = abi.encodeWithSelector(bytes4(0x3ec37834), 42);
// bytes4(0x3ec37834) 是 setValue(uint256) 的 selector
```

**用途**：用 Selector + 参数，生成完整调用数据（比 WithSignature 省一次 keccak256 计算）。

#### abi.encodeCall（最安全）

```solidity
bytes memory data = abi.encodeCall(someFunction, (42));
// 编译时检查参数类型是否匹配
```

**推荐理由**：编译时类型检查，错误提前发现，不会在运行时才发现参数不匹配。

### ABI 编码格式示例

```
调用 setValue(42) 的 ABI 数据格式：

| Selector (4 bytes) | 参数编码 (32 bytes) |
| 0x3ec37834         | 0x0000...002a (42) |
```

每个参数都填充到 32 字节（256 位），不足的左侧补零。

## 5. 代码拆解

### ABI 编解码完整示例

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ABIDemo {
    // 值类型参数
    function encodeUint() external pure returns (bytes memory) {
        return abi.encode(uint256(42), address(0x123));
    }

    function decodeUint(bytes calldata _data) external pure returns (uint256, address) {
        return abi.decode(_data, (uint256, address));
    }

    // abi.encodeWithSignature 用法
    function encodeWithSig() external pure returns (bytes memory) {
        return abi.encodeWithSignature("setValue(uint256)", 100);
    }

    // abi.encodeWithSelector 用法
    function encodeWithSel() external pure returns (bytes memory) {
        bytes4 selector = bytes4(keccak256("setValue(uint256)"));
        return abi.encodeWithSelector(selector, 100);
    }

    // 函数选择器
    function getSelector() external pure returns (bytes4) {
        return bytes4(keccak256("setValue(uint256)"));
    }

    // 用 .selector 属性获取选择器
    function getSelector2() external pure returns (bytes4) {
        return this.setValue.selector;
    }

    // abi.encodeCall（最安全）
    function encodeCall() external pure returns (bytes memory) {
        return abi.encodeCall(this.setValue, (200));
    }

    // 占位函数（用于测试 selector）
    function setValue(uint256 _value) external pure {
        // just for test
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/16_ABIDemo.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ABIDemo {
    struct User {
        uint256 uid;
        bytes name;
    }

    // 基础 encode/decode
    function encodeValues() external pure returns (bytes memory) {
        return abi.encode(uint256(1), address(0x123));
    }

    function decodeValues(bytes memory _data) external pure returns (uint256, address) {
        return abi.decode(_data, (uint256, address));
    }

    // encodeWithSignature
    function encodeWithSig() external pure returns (bytes memory) {
        return abi.encodeWithSignature("mint(address,uint256)", address(0x123), 100);
    }

    // Selector 计算
    function getSelector() external pure returns (bytes4) {
        return bytes4(keccak256("mint(address,uint256)"));
    }

    // .selector 方式
    function getSelector2() external pure returns (bytes4) {
        return this.mint.selector;
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
cat > test/16_ABIDemo.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/16_ABIDemo.sol";

contract ABIDemoTest is Test {
    ABIDemo public demo;

    function setUp() public {
        demo = new ABIDemo();
    }

    function testEncodeAndDecode() public {
        bytes memory encoded = demo.encodeValues();
        (uint256 num, address addr) = demo.decodeValues(encoded);
        assertEq(num, 1);
        assertEq(addr, address(0x123));
    }

    function testSelector() public {
        bytes4 sel1 = demo.getSelector();
        bytes4 sel2 = demo.getSelector2();
        assertEq(sel1, sel2);
    }

    function testEncodeWithSig() public {
        bytes memory data = demo.encodeWithSig();
        // Selector + 参数编码
        assertTrue(data.length > 4);
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

### 错误 1：abi.decode 类型不匹配

- **常见原因**：解码时的类型顺序或数量和编码时不匹配
- **解决步骤**：
  1. 确认编码时用了几个参数
  2. 确认解码时的类型和顺序与编码完全一致
  ```solidity
  // 编码: encode(uint256, address, bytes)
  // 解码: decode(_data, (uint256, address, bytes))
  ```
- **验证方式**：`forge test` 测试解码正确性

### 错误 2：abi.encodeWithSignature 函数名拼写错误

- **常见原因**：`"setValue(uint256)"` 拼成 `"setValue (uint256)"`（多了空格）
- **解决步骤**：
  1. 检查函数签名是否完全匹配（包括空格）
  2. 建议用 `abi.encodeCall` 替代，自动从函数指针获取签名
- **验证方式**：`forge build` 不会报错，但 call 会失败

### 错误 3：selector 计算错误

- **常见原因**：函数签名中参数类型写法不对（如 `uint` vs `uint256`）
- **解决步骤**：确认参数类型是完整类型（`uint256` 而非 `uint`，`bool` 而非 `boolean`）
- **验证方式**：用 foundry 的 `cast sig "函数签名"` 命令验证：
  ```bash
  cast sig "setValue(uint256)"
  # 输出: 0x3ec37834
  ```

## 9. 本节总结

- **ABI** = 合约调用数据的编码格式，约定了如何打包参数和解读返回值
- **Selector** = 函数签名的 keccak256 哈希前 4 字节，用于指定目标函数
- **`abi.encode`** = 把参数打包成字节
- **`abi.decode`** = 把字节还原成参数
- **`abi.encodeWithSignature`** = Selector + 参数，一步完成
- **`abi.encodeWithSelector`** = 手写 Selector + 参数
- **`abi.encodeCall`** = 最安全（编译时检查类型）
- **selector 获取方式**：`bytes4(keccak256("foo(uint256)"))` 或 `this.foo.selector`

## 10. 课后练习

### 练习 1
写一个 `ABIPractice` 合约，包含：
- `function encodeUser(address _addr, uint256 _uid, bytes memory _name) external pure returns (bytes memory)` — 编码用户信息
- `function decodeUser(bytes memory _data) external pure returns (address, uint256, bytes memory)` — 解码用户信息
- 用测试验证：编码后解码，能还原出原始的三个值

### 练习 2
用 `cast` 命令行工具验证 Selector：
- 用 `cast sig "transfer(address,uint256)"` 查看 selector
- 用 `cast sig "balanceOf(address)"` 查看 selector
- 用 `cast call <合约地址> "函数签名"` 实际调用合约（需要 anvil）
- 把验证结果记录到练习报告

## 11. 官方参考

- [ABI 编码函数](https://docs.soliditylang.org/en/v0.8.35/abi-spec.html)
- [函数选择器（Function Selector）](https://docs.soliditylang.org/en/v0.8.35/abi-spec.html#function-selector)
- [abi.encode 与 abi.decode](https://docs.soliditylang.org/en/v0.8.35/abi-spec.html#encoding)