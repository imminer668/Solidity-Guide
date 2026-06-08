# 第 46 课:TransparentProxy —— 透明代理

## 1. 本节目标

学完这节课,你能:
- 说清"为什么普通 Proxy 会出现选择器冲突,透明代理怎么解决"
- 自己手写一个带 admin 路径隔离的 TransparentProxy(raw 实现)
- 理解 "admin 路径 vs 用户路径" 的双分支设计
- 识别透明代理与 UUPS 的取舍
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 44 课:Proxy 模式
- 第 45 课:Upgrade(可升级合约)
- 第 17 课:合约调用 + 函数选择器(`bytes4` selector 是核心)

## 3. 先讲结论

**TransparentProxy(透明代理) = 升级合约 + admin 路径与用户路径隔离**。典型场景:
- **OZ TransparentUpgradeableProxy**:最早期的工业级代理(2018+)
- **大多数 DeFi 协议**:Aave、Compound 早期版本都用透明代理
- **风险隔离**:防 admin 误调 Logic 函数,引发"选择器冲突"灾难

**为什么需要透明代理?选择器冲突问题**

假设 Logic 有 `function transfer(address)`,Proxy 有 `function upgrade(address)`。两者的 4-byte selector **完全可能相同**(`0xa9059cbb` ≠ `0x99a88ec4` 看起来不会撞,但理论上 4 字节空间只有 42 亿可能,工程上会撞)。

```
admin 调 proxy.upgrade(0x123) → selector = 0x99a88ec4
    ↓
普通 Proxy 没有 upgrade 函数(写在 Logic 里) → 进 fallback → delegatecall Logic
    ↓
如果 Logic 恰好有 selector 0x99a88ec4 的函数 → 被误调,bug!
```

**透明代理的解决思路:看 msg.sender 分流**

```
admin 调用:
  if 调 upgrade/transferAdmin → 直接走 proxy 自己的函数
  else 调其他 → revert(防误用 Logic)

用户调用:
  always 走 fallback → delegatecall Logic
```

**核心规则**:
```solidity
fallback() external payable {
    require(msg.sender != admin);    // admin 禁止走 fallback
    delegatecall(...);
}
```

这样保证 admin **只能调 Proxy 自己的管理函数**,绝不会触发 Logic 的函数。

**与 45 课的差异**:
| 维度 | 45 课 (Upgrade) | 46 课 (TransparentProxy) |
|------|-----------------|--------------------------|
| fallback 鉴权 | 无,任何人都能走 | `require(msg.sender != admin)` |
| admin 调 Logic | 允许(隐患!) | 禁止(透明!) |
| 适用场景 | 教学演示 | 准生产(还需加 EIP-1967) |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/TransparentProxy.sol` + `Logic1.sol` + `Logic2.sol` | 30 + 14 + 14 行 |
| **oz** | `src/oz/TransparentProxy.sol` | 11 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 命名占位。**生产环境**用 OZ `TransparentUpgradeableProxy` + `ProxyAdmin`,把 admin 角色放在专门的合约里,逻辑更清晰。

## 4. 合约设计

### 4.1 关键代码:fallback 中的鉴权

```solidity
fallback() external payable {
    require(msg.sender != admin);              // ★ 核心:admin 走不到 fallback
    (bool success, ) = implementation.delegatecall(msg.data);
    success; // suppress warning
}
```

教学点:
- `require(msg.sender != admin)`:把 admin 路径"切断",admin 调任何 Logic 函数都 revert
- `success;` 是为了消除"unused variable"警告

### 4.2 upgrade 函数(只允许 admin)

```solidity
function upgrade(address newImplementation) external {
    if (msg.sender != admin) revert();
    implementation = newImplementation;
}
```

要点:
- 用 `if + revert()` 与 `require` 等价(教学版风格)
- 只有 admin 能升级,普通用户调 upgrade 直接 revert

### 4.3 两条路径

```
路径 A(用户):
  user → proxy.foo()
       → proxy 没有 foo() → fallback
       → msg.sender != admin ✓ → delegatecall Logic.foo()
       
路径 B(admin):
  admin → proxy.upgrade(newImpl)
        → proxy 自己的 upgrade() 函数,直接执行
        → 不走 fallback,不会误调 Logic
        
路径 C(admin 误调 Logic 函数):
  admin → proxy.foo()
       → proxy 没有 foo() → fallback
       → msg.sender == admin ✗ → revert(透明!)
```

### 4.4 业务流程

```
部署 logic1, logic2
admin 部署 proxy(logic1)
   ↓
用户:address(proxy).call(foo())   ← 用户调,delegatecall Logic1,words = "old"
   ↓
admin 不能调 foo(),只能调 upgrade:
admin.upgrade(logic2)               ← 切换 implementation
   ↓
用户再调 foo() → delegatecall Logic2,words = "new"
   ↓
admin 调 foo() → revert(不允许)
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/TransparentProxy.sol`

完整代码(30 行):

```solidity
contract TransparentProxy {
    address public implementation;
    address public admin;
    string public words;
    
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }
    
    fallback() external payable {
        require(msg.sender != admin);                              // ★ 透明性核心
        (bool success, ) = implementation.delegatecall(msg.data);
        success;
    }
    
    function upgrade(address newImplementation) external {
        if (msg.sender != admin) revert();
        implementation = newImplementation;
    }
    
    receive() external payable {}
}
```

要点:
- `receive()` 接收 ETH(不带 calldata 的)
- 注意 `fallback` 的 `require` —— 这是与 45 课 `SimpleUpgrade` 的唯一区别

### 5.2 Logic1 / Logic2(与 45 课完全一致)

```solidity
contract Logic1 {
    address public implementation;
    address public admin;
    string public words;
    function foo() public { words = "old"; }
}
contract Logic2 {
    address public implementation;
    address public admin;
    string public words;
    function foo() public { words = "new"; }
}
```

教学点:存储布局必须与 Proxy 一致(槽 0/1/2:implementation/admin/words)。

### 5.3 oz 实现 —— `src/oz/TransparentProxy.sol`

```solidity
import {TransparentProxy} from "../../src/raw/TransparentProxy.sol";

contract TransparentProxyOZ is TransparentProxy {
    constructor(address _implementation) TransparentProxy(_implementation) {}
}
```

要点:业务完全一致,本项目 oz 版只是命名占位。

### 5.4 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| 代码量 | 30+14+14=58 行 | 11 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 OZ `TransparentUpgradeableProxy` + `ProxyAdmin`**:
- 把 admin 角色放在独立的 `ProxyAdmin` 合约里
- ProxyAdmin 是另一个合约,有独立的 owner
- 升级路径:user → ProxyAdmin.upgrade → TransparentProxy.upgrade
- 完整支持 EIP-1967 标准 slot

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/10_upgrade_governance/46_TransparentProxy
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── TransparentProxy.sol     # 30 行,带 admin 路径隔离
│   ├── Logic1.sol               # 14 行,foo() = "old"
│   └── Logic2.sol               # 14 行,foo() = "new"
└── oz/TransparentProxy.sol      # OZ 版(继承 raw)
test/
├── raw/TransparentProxy.t.sol   # 8 个测试
└── oz/TransparentProxy.t.sol    # 2 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 10 个测试全部通过(raw 8 个 + oz 2 个)。

### 步骤 5:重点测试 —— admin 透明性(`test/raw/TransparentProxy.t.sol`)

```solidity
function testAdminCannotCallLogicContract() public {
    // 测试合约本身就是 admin(setUp 部署 proxy)
    (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
    assertEq(success, false);                  // ★ admin 调 foo() 失败!
}

function testNonAdminCanCallLogicContract() public {
    vm.prank(address(0x1234));                  // 切换 msg.sender 为非 admin
    (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
    require(success, "Call from non-admin should succeed");
    assertEq(proxy.words(), "old");             // ★ 非 admin 调成功
}
```

教学点:
- **同样调 foo()**,admin 调失败,非 admin 调成功
- 这就是"透明"的核心:admin 看到的是 Proxy 自己,用户看到的是 Logic

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 10 个测试全部 PASS:
  - **raw**: `testInitialState`、`testProxyCallThroughLogic1`、`testAdminCannotCallLogicContract`、`testNonAdminCanCallLogicContract`、`testUpgrade`、`testProxyCallAfterUpgrade`、`testOnlyAdminCanUpgrade`、`testWordsChangedByLogic1`
  - **oz**: `testInitialState`、`testProxyCallThroughLogic1`

## 8. 常见错误排查

### 错误 1:测试中 admin 调 foo() 应该 revert 但实际成功了

- **常见原因**:`setUp` 后没 `vm.prank(其他地址)`,导致 msg.sender = address(this) = admin
- **解决步骤**:`vm.prank(0x1234)` 切换 sender,模拟非 admin 用户
- **验证方式**:`testAdminCannotCallLogicContract` 验证 admin 调 foo 返回 success=false

### 错误 2:admin 想升级但 revert

- **常见原因**:admin 可能不小心通过 fallback 路径调了 upgrade(实际不会,但要确保 selector 准确)
- **解决步骤**:确保用 `proxy.upgrade(...)` 直接调,不要走 `address(proxy).call(...)`
- **验证方式**:`testUpgrade` 用 `proxy.upgrade()` 而非 `.call()`

### 错误 3:用户调 upgrade 应该 revert 但成功了

- **常见原因**:upgrade 函数忘了 `if (msg.sender != admin) revert()`
- **解决步骤**:upgrade 第一行必须鉴权
- **验证方式**:`testOnlyAdminCanUpgrade` 用 `vm.prank(0x1234)` 测非 admin 升级 revert

### 错误 4:Proxy 选择器冲突

- **常见原因**:Proxy 自己有 `function foo()`,与 Logic 的 `foo()` 撞 selector
- **解决步骤**:Proxy 只保留管理函数(upgrade / transferAdmin),所有业务函数放在 Logic
- **验证方式**:Proxy 合约里 **只暴露 `upgrade` 和必要 view**,不写业务函数

## 9. 本节总结

- TransparentProxy = Upgrade + admin 路径与用户路径隔离
- 核心:**fallback 中 `require(msg.sender != admin)`**,admin 走不到 delegatecall
- 解决选择器冲突:admin 调 Logic 函数会 revert,防误用
- 与 45 课唯一差别在 fallback 多一行 require
- 与 UUPS(47 课)对比:Transparent 把 upgrade 写在 Proxy,UUPS 写在 Logic(更省 gas)
- 生产用 OZ `TransparentUpgradeableProxy` + `ProxyAdmin`,admin 角色独立
- 实战:OZ 的 TransparentUpgradeableProxy 是 DeFi 最广泛使用的代理

## 10. 课后练习

### 练习 1
为 TransparentProxy 加 **transferAdmin 函数**:
- `function transferAdmin(address newAdmin) external` 让 admin 转让管理权
- 加测试:admin 调成功,非 admin 调 revert,转让后老 admin 失权

### 练习 2
为 TransparentProxy 加 **升级历史记录**:
- 加 `address[] public implementationHistory;` 记录每次升级
- upgrade 时 push 新 implementation 到历史
- 加测试:多次升级后,历史数组按时间顺序记录

### 练习 3(进阶)
基于 raw 的 TransparentProxy,实现 **ProxyAdmin 模式**:
- 加独立的 `ProxyAdmin` 合约,持有多个 TransparentProxy
- TransparentProxy 的 admin 设为 ProxyAdmin 合约地址
- 通过 `proxyAdmin.upgrade(proxyAddr, newImpl)` 间接升级
- 加测试:owner 通过 ProxyAdmin 升级 N 个 Proxy
- 提示:这是 OZ 工业级用法,把 admin 权限从 EOA 解耦到合约
