# 第 44 课:ProxyContract —— 代理合约模式

## 1. 本节目标

学完这节课,你能:
- 说清"为什么以太坊合约不可变,但还能升级"
- 自己手写一个最小可用的 Proxy(raw 实现)
- 区分 `call` 与 `delegatecall` 的本质差异
- 理解"Proxy 存数据,Logic 存代码"的状态分离思想
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 14 课:Eth 与 fallback(Proxy 必须有 fallback)
- 第 17 课:合约调用(`call` / `delegatecall` 的区别是核心)
- 第 11 课:存储槽(Proxy 与 Logic 的存储布局必须一致)

## 3. 先讲结论

**Proxy(代理合约) = 用户调用 Proxy 地址,Proxy 通过 `delegatecall` 把逻辑转发到 Logic 合约**。典型场景:
- **可升级合约**:Logic 可换,Proxy 不动 → 用户地址不变,逻辑能改
- **EIP-1967 / TransparentProxy / UUPS**:OZ 的工业级代理模式
- **节省 gas**:多份 Proxy 复用同一份 Logic 代码(部署 Proxy 比部署 Logic 便宜)
- **AccessControl 代理**:统一鉴权入口,后端实现按业务拆分

**核心概念:`call` vs `delegatecall`**

| 维度 | `call` | `delegatecall` |
|------|--------|----------------|
| 执行代码 | 被调方的 | 被调方的 |
| 状态修改 | 改被调方的存储 | 改**调用方**的存储 |
| `msg.sender` | 变成调用方 | 保留原 `msg.sender` |
| `msg.value` | 转给被调方 | 保留原 `msg.value` |
| 场景 | 普通跨合约调用 | 代理模式专用 |

**举栗对比:Logic 合约里 `x = 99`,Proxy 里 `x = 0`,调 `increment()` 返回多少?**

```
直接调 logic.increment()    → 用 logic.x = 99,返回 99 + 1 = 100
proxy.call increment()      → delegatecall,用 proxy.x = 0,返回 0 + 1 = 1
```

**关键陷阱:存储布局必须一致**

```
Proxy 槽 0:address implementation
Logic 槽 0:address implementation    ← 必须占同一个槽!
Logic 槽 1:uint256 x
```
如果不一致,delegatecall 会写错存储位置,变量数据全乱。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/Proxy.sol`(Proxy + Logic + Caller) | 70 行 |
| **oz** | `src/oz/Proxy.sol` | 10 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 命名占位。**生产环境**用 OZ `ERC1967Proxy` / `TransparentUpgradeableProxy` / `UUPSUpgradeable`(45~47 课讲)。

## 4. 合约设计

### 4.1 Proxy 状态(只有一个)

```solidity
contract Proxy {
    address public implementation;   // 槽 0:Logic 合约地址
    
    constructor(address implementation_) {
        implementation = implementation_;
    }
}
```

要点:`implementation` 必须放在槽 0,且 Logic 也要在槽 0 放同样字段(占位),否则 delegatecall 时存储错位。

### 4.2 关键代码:fallback + delegatecall

```solidity
fallback() external payable {
    address _implementation = implementation;
    assembly {
        calldatacopy(0, 0, calldatasize())                                    // 1. 拷贝 calldata
        let result := delegatecall(gas(), _implementation, 0, calldatasize(), 0, 0)  // 2. delegatecall
        returndatacopy(0, 0, returndatasize())                                 // 3. 拷贝返回值
        switch result
        case 0 { revert(0, returndatasize()) }                                 // 失败 revert
        default { return(0, returndatasize()) }                                // 成功 return
    }
}
```

教学点:
- **必须用 assembly**:Solidity 高级语法的 `address.delegatecall(...)` 拿不到完整 calldata + return
- `calldatacopy`:把外部调用的 calldata 拷贝到内存
- `delegatecall(gas, addr, in, inSize, out, outSize)`:核心 opcode
- `returndatacopy` + `return`:把 Logic 的返回值原样转给 caller

### 4.3 Logic 合约(被代理的逻辑)

```solidity
contract Logic {
    address public implementation;    // 槽 0(占位,与 Proxy 对齐)
    uint256 public x = 99;             // 槽 1
    
    function increment() external returns (uint256) {
        return x + 1;
    }
}
```

要点:
- **第一个字段 `implementation` 是占位**:Logic 自己不用,但必须有,保证 delegatecall 时 Proxy 的 `implementation` 不被 `x` 覆盖
- `x = 99`:Logic 自己当 standalone 时 x 是 99;但通过 Proxy delegatecall 时,**用的是 Proxy 的 x(默认 0)**
- 真实生产中:Logic 通常不写 `= 99` 初始值,因为 Proxy 不会跑 Logic 的 constructor

### 4.4 Caller 合约(测试用)

```solidity
contract Caller {
    address public proxy;
    
    function increment() external returns (uint256) {
        (bool success, bytes memory data) = proxy.call(
            abi.encodeWithSignature("increment()")
        );
        return abi.decode(data, (uint256));
    }
}
```

要点:Caller 演示"用户的合约怎么调 Proxy"。注意是 `call`(不是 delegatecall)—— Caller 是普通调用 Proxy。

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/Proxy.sol`

包含 3 个合约:

| 合约 | 作用 | 状态 |
|------|------|------|
| `Proxy` | 代理入口 | `address implementation` |
| `Logic` | 逻辑实现 | `address implementation; uint256 x = 99;` |
| `Caller` | 外部用户合约 | `address proxy` |

#### fallback delegatecall 完整流程

```
用户 → caller.increment()
       ↓
     caller.call(proxy, "increment()")
       ↓
     proxy.fallback() 触发(因为 Proxy 本身没有 increment 函数)
       ↓
     assembly: delegatecall(logic, "increment()")
       ↓
     Logic 的 increment() 代码跑在 Proxy 的存储上
       ↓
     x + 1 = 0 + 1 = 1 (用 Proxy 的 x,不是 Logic 的)
       ↓
     return 1 → caller → 用户
```

### 5.2 三种调用场景对比

| 场景 | 调用方式 | 用谁的 x | 返回值 |
|------|--------|---------|--------|
| 直接调 Logic | `logic.increment()` | Logic.x = 99 | 100 |
| 通过 Proxy 调 | `proxy.call("increment()")` | Proxy.x = 0 | 1 |
| 通过 Caller 调 Proxy | `caller.increment()` | Proxy.x = 0 | 1 |

教学点:**同一份 Logic 代码,通过不同入口调用,结果不同**。这就是代理模式的核心:**代码 = Logic 的,数据 = 调用入口的**。

### 5.3 oz 实现 —— `src/oz/Proxy.sol`

```solidity
import {Proxy} from "../../src/raw/Proxy.sol";

contract ProxyOZ is Proxy {
    constructor(address implementation_) Proxy(implementation_) {}
}
```

要点:业务完全一致,本项目 oz 版只是命名占位。

### 5.4 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| 代码量 | 70 行 | 10 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 OZ `ERC1967Proxy`**:遵循 EIP-1967 标准,把 `implementation` 存到特定 slot(`bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)`),防止业务合约误改。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/10_upgrade_governance/44_ProxyContract
```

### 步骤 2:查看文件结构

```
src/
├── raw/Proxy.sol           # 原生 Proxy + Logic + Caller(~70 行)
└── oz/Proxy.sol            # OZ 版(继承 raw)
test/
├── raw/Proxy.t.sol         # 4 个测试
└── oz/Proxy.t.sol          # 2 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 6 个测试全部通过(raw 4 个 + oz 2 个)。

### 步骤 5:重点测试 —— delegatecall 存储分离(`test/raw/Proxy.t.sol`)

```solidity
function testDirectLogicCall() public {
    assertEq(logic.increment(), 100);   // Logic.x = 99, +1 = 100
}

function testProxyCall() public {
    (, bytes memory data) = address(proxy).call(
        abi.encodeWithSignature("increment()")
    );
    uint256 result = abi.decode(data, (uint256));
    assertEq(result, 1);                  // Proxy.x = 0(未初始化), +1 = 1
}
```

教学点:
- **同一份 Logic 代码**,直接调返回 100,通过 Proxy 调返回 1
- 差异来源:`delegatecall` 让 Logic 的代码用 Proxy 的存储
- Proxy 的 `x` 没初始化所以是 0(Solidity 默认值)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 6 个测试全部 PASS:
  - **raw**: `testInitialState`、`testDirectLogicCall`、`testProxyCall`、`testCallerThroughProxy`
  - **oz**: `testInitialState`、`testProxyCall`

## 8. 常见错误排查

### 错误 1:Proxy 调用返回错的值(如预期 1,实际 100)

- **常见原因**:Proxy.sol 里 fallback 用了 `.call` 而非 `delegatecall`
- **解决步骤**:assembly 中确保是 `delegatecall(gas(), ...)`,不是 `call(gas(), ..., value, ...)`
- **验证方式**:`testProxyCall` 检查返回 1 而非 100

### 错误 2:存储槽错位,数据乱

- **常见原因**:Logic 的第一个字段不是 `address implementation`,导致 delegatecall 时 Proxy 的 implementation 被覆盖
- **解决步骤**:Logic 的存储布局必须以 `address implementation` 开头(或用 EIP-1967 独立 slot)
- **验证方式**:升级合约后,proxy.implementation() 还能正确返回新地址

### 错误 3:Proxy 调用 revert "EvmError: Revert"

- **常见原因**:Logic 合约里函数 selector 不存在(签名错)
- **解决步骤**:`abi.encodeWithSignature("functionName(uint256)")` 参数类型与 Logic 一致
- **验证方式**:用 `cast sig "functionName(uint256)"` 算 selector,再用 `cast 4byte 0xXXXX` 反查 ABI

### 错误 4:升级后老用户调用 revert

- **常见原因**:新 Logic 的存储布局与老 Logic 不一致(如插了新变量在中间)
- **解决步骤**:新 Logic **只能往后加字段**,绝不能改老字段顺序/类型
- **验证方式**:用 OZ 工具 `forge inspect storage-layout` 比对升级前后槽位

## 8.5 本课安全边界

> 集中安全知识见第 20 课(常见漏洞与防护),本节只列**与 Proxy / delegatecall 直接相关**的坑点。

### 坑 1:Logic 存储布局与 Proxy 不一致 → 状态错位

**现象**:Proxy 槽 0 是 `address implementation`,Logic 槽 0 也是 `address implementation`(占位)。但某次升级,新 Logic 把第一个字段改成 `address newVariable`:
```solidity
// 旧 Logic:槽 0 = address implementation
// 新 Logic:槽 0 = address newVariable,槽 1 = address implementation
```
→ `delegatecall` 用 Proxy 槽 0 读 `newVariable`,**实际读到的是 `implementation` 的值**(被误读为变量)→ 状态错乱。

**修复**:
- 升级合约时**只能往后加字段**,**不能改老字段顺序/类型**
- 升级前用 `forge inspect storage-layout` 比对升级前后槽位
- 生产用 `ERC7201` 命名存储(namespace 化布局,44 课延伸阅读)

### 坑 2:selector 冲突(Proxy fallback 与 Logic 函数)

**现象**:用户调 Proxy 上一个 selector 0x1234...,但这个 selector 正好命中 Proxy 自己**已定义的函数**(如 `implementation()`),而**不是** Logic 里的某个函数。fallback 不触发,直接走 Proxy 的实现 → 用户以为在调 Logic,实际是 Proxy。

**修复**:
- Proxy **只保留**:
  - constructor(部署 implementation)
  - `receive() / fallback()`(delegatecall)
  - 可选:`upgradeTo(...)`(本课练习 1)
- **不要在 Proxy 上加任何业务函数**(包括 `implementation()` getter 应放 Logic 内)
- 升级模式(Tansparent / UUPS)有标准方法处理 selector 冲突

### 坑 3:Logic 合约 constructor 在 Proxy 部署时**不会执行**

**现象**:Logic 合约的 constructor `Logic { x = 99; }` 只在**直接部署 Logic 时代码跑一次**(初始化 Logic 自己的 storage)。**Proxy 部署时不会跑 Logic 的 constructor** → Proxy 槽 1 的 `x` 永远默认 0(本课正文 line 244 的例子)。

**修复**:
- Logic 不用 constructor,用 **`initialize(address, ...)` 函数 + `initializer` modifier**(OZ 模式)
- Proxy 部署时 delegatecall 调 Logic.initialize() 完成一次性初始化
- `initializer` modifier 防二次初始化

```solidity
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract LogicV1 is Initializable {
    uint256 public x;
    
    function initialize(uint256 _x) external initializer {
        x = _x;
    }
}
```

### 坑 4:Logic 部署时抢跑攻击(initialize 抢跑)

**现象**:项目方部署 Proxy(没初始化),**攻击者看到部署交易**,抢在项目方之前调 `Logic.initialize(...)` → Logic 状态被攻击者设值 → 项目方再调 `initialize` 失败(因 `initializer` 修饰)。

**修复**:
- **Proxy 部署时同笔交易 delegatecall 调 `initialize()`**(EIP-1967 Proxy 标准做法)
- `initializer` modifier **严格**只在第一次成功,**防跨函数绕过**
- 用 `initVersion` 等机制防"分叉重置"

### 坑 5:delegatecall 失败时,Proxy 状态被部分修改

**现象**:Logic 合约函数没遵循 CEI,先 `state++` 后调别的合约。`state++` 写的是 **Proxy** 的 storage。如果后续调用失败,`state++` **不会回滚**?

实际:**delegatecall 失败 → 整笔 revert → 所有 storage 改动回滚**(EVM 原子性保证)。但**单个 sub-call 失败**不一定回滚外部效果(如 token 转账已发出去),所以 CEI 仍必要。

**修复**:
- Logic 函数遵循 **CEI**:先校验 → 写状态 → 外部调用
- 重要函数加 `nonReentrant`

### 坑 6:implementation slot 没存到 EIP-1967 标准 slot

**现象**:本课 raw 版 Proxy 把 `implementation` 存到槽 0,**容易被业务合约误改**:
- Logic 升级时,假设新 Logic 槽 0 = `uint256 x`,delegatecall 写 x 时**把 implementation 覆盖了** → 下次调用全废。

**修复**:用 EIP-1967 规定的特定 slot:
```solidity
bytes32 internal constant _IMPLEMENTATION_SLOT =
    bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);

function _getImplementation() internal view returns (address) {
    return StorageSlot.getAddressSlot(_IMPLEMENTATION_SLOT).value;
}
```

生产用 OZ `ERC1967Proxy` / `TransparentUpgradeableProxy` / `UUPSUpgradeable`(45-47 课)。

### 坑 7:upgradeTo 没权限控制

**现象**:`function upgrade(address newImpl) external { implementation = newImpl; }` 任何人都能调,攻击者把自己的恶意 Logic 设为 implementation → 用户调 Proxy 全部走恶意 Logic → 资产被盗。

**修复**:
- `upgradeTo` 加 `onlyOwner` / `onlyAdmin` / `onlyGovernance`
- UUPS 模式:升级函数在 Logic 内(本课进阶)
- 多签(48 课)或 Timelock(33 课)防单点失误

### 关键防御清单

| 风险 | 防御 |
|------|------|
| 存储布局错位 | 升级时只往后加字段,用 `forge inspect storage-layout` 比对 |
| selector 冲突 | Proxy 不放业务函数,只留 fallback / 升级函数 |
| constructor 不跑 | 用 `initialize()` + `initializer` modifier |
| initialize 抢跑 | 部署时同笔交易 delegatecall 调 initialize |
| 部分状态回滚 | 严格 CEI,加 `nonReentrant` |
| implementation slot 误改 | 用 EIP-1967 / ERC-7201 标准 slot |
| 升级无权限 | `onlyOwner` / 多签 / Timelock |

> 集中讲 Proxy 安全的还有第 45-47 课(Transparent / UUPS / Beacon),本节先把 Proxy 自己的坑列出来。

## 9. 本节总结

- Proxy = **delegatecall 把调用转发到 Logic**,实现"代码可换、数据不变"
- 核心:**`delegatecall` 用被调方的代码 + 调用方的存储**
- 关键约束:**Proxy 与 Logic 的存储布局必须一致**(从槽 0 开始)
- assembly 实现 fallback:`calldatacopy` → `delegatecall` → `returndatacopy` → `return`
- 三种调用场景:直接 Logic / 通过 Proxy / 通过 Caller,结果不同
- 与本单元其他课对比:本课是**升级合约的基石**,45~47 课在此基础上引入升级机制
- 配合 OZ `ERC1967Proxy`:EIP-1967 标准的 slot 存储,防误改
- 写 Proxy 最常踩的坑:存储布局错位、selector 冲突、constructor 不跑、initialize 抢跑、升级无权限

## 10. 课后练习

### 练习 1
为 Proxy 加 **升级功能**:
- 加 `function upgrade(address newImpl) external` 让 owner 改 implementation
- 加 `onlyOwner` modifier(用 Ownable)
- 加测试:升级后调用同样函数,但走新 Logic 的代码

### 练习 2
为 Proxy 加 **构造参数转发**:
- 让 Proxy 接受 `bytes calldata initData`
- 部署时 delegatecall 调 Logic 的 `initialize(...)`
- 加测试:部署 Proxy 后,Logic 的初始化函数被调用,Proxy 的状态被正确初始化

### 练习 3(进阶)
实现 **"信标代理"模式(Beacon Proxy)**:
- 加 `Beacon` 合约存 implementation,Proxy 从 Beacon 读取
- 升级时改 Beacon 一次,所有 Proxy 都升级
- 加测试:部署 N 个 Proxy 都指向同一 Beacon,升级 Beacon 后所有 Proxy 都用新 Logic
- 提示:这是 OZ `BeaconProxy` 的简化版,适合工厂模式部署多个相同合约
