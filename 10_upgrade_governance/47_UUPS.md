# 第 47 课:UUPS —— 通用可升级代理标准

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 UUPS 比 TransparentProxy 更省 gas"
- 自己手写一个把升级函数放在 Logic 里的 UUPSProxy(raw 实现)
- 理解 UUPS 最大的坑:**Logic 漏写 upgrade 合约永久不能升级**
- 区分 UUPS / Transparent / 普通 Proxy 三种升级模式
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 44 课:Proxy 模式
- 第 45 课:Upgrade(可升级合约)
- 第 46 课:TransparentProxy
- 第 17 课:合约调用(`delegatecall` 是核心)

## 3. 先讲结论

**UUPS(Universal Upgradeable Proxy Standard,EIP-1822) = 把升级函数从 Proxy 移到 Logic**。典型场景:
- **OZ UUPSUpgradeable**:OZ 4.x+ 主推的代理模式
- **新协议默认选择**:Optimism、Arbitrum 等 L2 项目大量采用
- **省 gas 场景**:每次 Proxy 部署节省 ~30% 字节码

**核心思想:升级函数搬家**

```
TransparentProxy 模式:
  Proxy {
    upgrade(newImpl) external onlyAdmin { ... }   ← upgrade 在这里
    fallback() { delegatecall logic }
  }
  Logic { foo() }
  
UUPS 模式:
  Proxy {
    fallback() { delegatecall logic }              ← Proxy 极简,只有 fallback
  }
  Logic {
    foo()
    upgrade(newImpl) external onlyAdmin { ... }    ← upgrade 在 Logic!
  }
```

**为什么这样省 gas?**
- Proxy 字节码更短(不含 upgrade 逻辑)→ 部署便宜
- 工厂模式部署多个 Proxy 时,累计省钱
- Logic 只部一份,upgrade 逻辑在 Logic 共享

**UUPS 调用 upgrade 的路径**:
```
admin 调 address(proxy).call(upgrade(newImpl))
   ↓
proxy 没有 upgrade → fallback → delegatecall logic.upgrade(newImpl)
   ↓
logic.upgrade 运行在 proxy 的存储上 → proxy.implementation = newImpl
```

**UUPS 最大的坑:升级永久失效**

```
v1 Logic 有 upgrade()  ✓
升级到 v2 Logic 没 upgrade()  ✗
   → 现在 proxy 委托到 v2,v2 没 upgrade 函数
   → 永远没办法再升级了!合约死了!
```

OZ 用 `_authorizeUpgrade` hook 强制提醒:你必须实现这个 + 继承 `UUPSUpgradeable`。

**与 46 课 TransparentProxy 的对比**:
| 维度 | TransparentProxy | UUPS |
|------|-----------------|------|
| upgrade 函数位置 | Proxy | Logic |
| Proxy 字节码 | 大(含 upgrade) | 小(只 fallback) |
| 部署 gas | 高 | 低 |
| 升级风险 | 低(upgrade 永远在) | 高(Logic 漏写=死锁) |
| 适用场景 | 谨慎稳健 | 工厂部署多 Proxy |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/UUPS.sol`(UUPSProxy + UUPS1 + UUPS2) | 62 行 |
| **oz** | `src/oz/UUPS.sol`(UUPSLogicV1OZ + UUPSLogicV2OZ) | 52 行 |

> 注:本项目 oz 版引入 OZ `UUPSUpgradeable` + `Initializable`(真用 OZ 而非命名占位)。**生产环境**完全用 OZ 这套,不要自己写 raw 版。

## 4. 合约设计

### 4.1 UUPSProxy(极简)

```solidity
contract UUPSProxy {
    address public implementation;
    address public admin;
    string public words;
    
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }
    
    fallback() external payable {
        implementation.delegatecall(msg.data);
    }
    
    receive() external payable {}
}
```

要点:
- **没有 upgrade 函数**(对比 TransparentProxy)
- **没有 admin 路径分支**(因为升级走 fallback → delegatecall)
- 只有 storage + fallback,字节码极小

### 4.2 UUPS1 / UUPS2(Logic 含 upgrade)

```solidity
contract UUPS1 {
    address public implementation;
    address public admin;
    string public words;
    
    function foo() public { words = "old"; }
    
    function upgrade(address newImplementation) external {   // ★ upgrade 在这!
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}

contract UUPS2 {
    address public implementation;
    address public admin;
    string public words;
    
    function foo() public { words = "new"; }
    
    function upgrade(address newImplementation) external {   // ★ 必须复制粘贴!
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

教学点:
- **每个 Logic 版本都必须有 upgrade 函数**,否则升级到没 upgrade 的版本会死锁
- 这就是 UUPS 最大的设计风险

### 4.3 业务流程

```
部署 uups1, uups2
admin 部署 proxy(uups1)
   ↓
用户:address(proxy).call(foo()) → delegatecall uups1.foo() → proxy.words = "old"
   ↓
admin:address(proxy).call(upgrade(uups2)) → delegatecall uups1.upgrade(uups2)
       → uups1.upgrade 在 proxy 的存储上跑 → proxy.implementation = uups2
   ↓
用户:address(proxy).call(foo()) → delegatecall uups2.foo() → proxy.words = "new"
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/UUPS.sol`(62 行)

包含 3 个合约:
- `UUPSProxy`(~23 行):极简代理,无 upgrade
- `UUPS1`(~18 行):Logic V1,foo = "old",含 upgrade
- `UUPS2`(~18 行):Logic V2,foo = "new",含 upgrade

#### Proxy 极简性

对比 46 课 TransparentProxy(30 行),UUPSProxy 砍掉 upgrade 函数后只剩 storage + fallback + receive,字节码显著更少。

#### 升级走 fallback 路径

升级时调用方式是 `address(proxy).call(upgrade(...))`:

```solidity
function testUpgradeToUUPS2() public {
    (bool success, ) = address(proxy).call(
        abi.encodeWithSelector(uups1.upgrade.selector, address(uups2))
    );
    require(success, "upgrade failed");
    assertEq(proxy.implementation(), address(uups2));
}
```

教学点:**通过 Proxy 调用 upgrade**,触发 delegatecall,运行的是 uups1.upgrade 代码但写的是 proxy 的存储。

### 5.2 oz 实现 —— `src/oz/UUPS.sol`(52 行)

#### UUPSLogicV1OZ
```solidity
contract UUPSLogicV1OZ is Initializable, UUPSUpgradeable {
    address public admin;
    string public words;
    
    function initialize(address _admin) public initializer {
        admin = _admin;
        words = "old";
    }
    
    function foo() public { words = "old v1"; }
    
    function _authorizeUpgrade(address newImplementation) internal override {}
}
```

要点:
- 继承 `UUPSUpgradeable` —— 自动提供 `upgradeToAndCall` 函数
- 必须实现 `_authorizeUpgrade` hook(就算空实现也得有,提醒你权限校验)
- `Initializable` + `initializer` modifier:替代 constructor(因 Proxy 不会调 Logic 的 constructor)
- `initializer` modifier 保证 `initialize()` 只能调一次

教学点:**OZ 用 `_authorizeUpgrade` 强制开发者考虑权限**,raw 版直接 `require(msg.sender == admin)` 看起来更简单但不安全(漏写就所有人能升级)。

#### UUPSLogicV2OZ(基本同 V1,差别在 foo 内容)

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| upgrade 实现 | 自己写 `require(msg.sender == admin)` | 继承 `UUPSUpgradeable`,实现 `_authorizeUpgrade` |
| initialize 模式 | 用 constructor | 用 `Initializable` + `initializer` |
| 升级提示 | 无(漏写直接死锁) | OZ 编译时强制提示 `_authorizeUpgrade` |
| 代码量 | 62 行 | 52 行 |
| 适用 | 学原理 | 生产 |

**生产用 OZ `UUPSUpgradeable`**:配合 `forge inspect storage-layout` 检测升级兼容性,配合 hardhat-upgrades 自动检测 `_authorizeUpgrade` 漏写。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/10_upgrade_governance/47_UUPS
```

### 步骤 2:查看文件结构

```
src/
├── raw/UUPS.sol           # 62 行,UUPSProxy + UUPS1 + UUPS2
└── oz/UUPS.sol            # 52 行,UUPSLogicV1OZ + UUPSLogicV2OZ
test/
├── raw/UUPS.t.sol         # 5 个测试
└── oz/UUPS.t.sol          # 3 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 8 个测试全部通过(raw 5 个 + oz 3 个)。

### 步骤 5:重点测试 —— 升级走 fallback(`test/raw/UUPS.t.sol`)

```solidity
function testFooAfterUpgrade() public {
    // 1. 调 UUPS1.foo,words = "old"
    address(proxy).call(abi.encodeWithSelector(uups1.foo.selector));
    assertEq(proxy.words(), "old");
    
    // 2. admin 升级到 UUPS2(注意:不是 proxy.upgrade,而是走 fallback)
    address(proxy).call(
        abi.encodeWithSelector(uups1.upgrade.selector, address(uups2))
    );
    
    // 3. 调 UUPS2.foo,words = "new"
    address(proxy).call(abi.encodeWithSelector(uups2.foo.selector));
    assertEq(proxy.words(), "new");
}
```

教学点:
- **升级也是 `.call(...)` 调 proxy**,通过 fallback 路径 delegatecall 到 Logic 的 upgrade
- 调 `uups1.foo.selector` 和 `uups2.foo.selector` 拿 selector(两者相同,都是 `0xc2985578`)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS:
  - **raw**: `testUUPSInitialState`、`testCallFooThroughProxy`、`testUpgradeToUUPS2`、`testFooAfterUpgrade`、`testNonAdminCannotUpgrade`
  - **oz**: 3 个测试覆盖核心流程

## 8. 常见错误排查

### 错误 1:升级新 Logic 后,合约再也不能升级了

- **常见原因**:新 Logic 漏写了 `upgrade()` 函数(UUPS 的"死锁"陷阱)
- **解决步骤**:
  - 用 OZ `UUPSUpgradeable` + `_authorizeUpgrade`(编译时检查)
  - 每次升级前 grep 新 Logic 是否含 upgrade 函数
- **验证方式**:升级前用 `forge inspect <NewLogic> methods` 看是否有 `upgrade`

### 错误 2:Logic 改了存储布局,升级后数据乱

- **常见原因**:UUPS2 的字段顺序与 UUPS1 不一致
- **解决步骤**:新 Logic **只能往后加字段**,不能改老字段顺序/类型
- **验证方式**:用 `forge inspect <Logic> storage-layout` 比对升级前后槽位

### 错误 3:非 admin 调 upgrade 没 revert

- **常见原因**:Logic 的 upgrade 漏写 `require(msg.sender == admin)`
- **解决步骤**:每个 Logic 的 upgrade 都必须鉴权
- **验证方式**:`testNonAdminCannotUpgrade` 用 `vm.prank(0x123)` 测非 admin 调用

### 错误 4:OZ 版部署后 initialize 被恶意抢调

- **常见原因**:没用 `Initializable` + `initializer` modifier
- **解决步骤**:OZ 版必须用 `initializer` modifier 保证只调一次
- **验证方式**:再次调 initialize 应 revert "InvalidInitialization"

## 9. 本节总结

- UUPS = 把 upgrade 函数从 Proxy 搬到 Logic 的代理模式(EIP-1822)
- 优势:**Proxy 极简,部署 gas 省 30%**
- 风险:**Logic 漏写 upgrade 函数 = 永久死锁**
- OZ 用 `UUPSUpgradeable` + `_authorizeUpgrade` hook 强制提示
- 与 Transparent 对比:UUPS 省 gas 但风险高,Transparent 稳健但贵
- 实战:Optimism、Arbitrum 等 L2 项目大量采用 UUPS
- 配合 EIP-1967 标准:OZ 自动把 implementation 存到独立 slot 防误改
- 工厂模式部署多 Proxy 时,UUPS 优势最明显

## 10. 课后练习

### 练习 1
为 UUPS Logic 加 **升级事件**:
- `event Upgraded(address indexed oldImpl, address indexed newImpl)`
- upgrade 函数中 emit
- 加测试:`vm.expectEmit` 校验事件

### 练习 2
为 UUPS Logic 加 **降级保护**:
- 新 Logic 必须实现 `function isValidImplementation() returns (bool)` 返回 true
- upgrade 前调 `newImpl.isValidImplementation()` 校验
- 加测试:正常 Logic 能升,空合约不能升

### 练习 3(进阶)
基于 raw 的 UUPS,实现 **EIP-1967 标准 slot**:
- implementation 存到 slot `bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)`
- 用 assembly `sload` / `sstore` 读写
- 加测试:即使 Logic 改了存储布局,implementation 不会被覆盖
- 提示:这是 OZ `ERC1967Proxy` 的核心特性,业务字段与 implementation 解耦
