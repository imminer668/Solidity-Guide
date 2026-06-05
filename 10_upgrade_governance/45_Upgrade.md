# 第 45 课:Upgrade —— 可升级合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么以太坊合约不可改,但升级模式能改"
- 自己手写一个 admin 可升级的 SimpleUpgrade(raw 实现)
- 理解"升级 = 改代码指针,storage 不动"
- 识别教学版与生产版(EIP-1967 / Transparent / UUPS)的差异
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 44 课:Proxy 模式(本课在 Proxy 基础上加 upgrade 函数)
- 第 17 课:合约调用(`delegatecall` 仍然是核心)
- 第 11 课:存储槽(Logic1 → Logic2 升级时,新 Logic 不能改老字段顺序)

## 3. 先讲结论

**Upgrade(可升级合约) = Proxy 模式 + admin 控制的 `upgrade(newImpl)` 函数**。典型场景:
- **协议 bug 修复**:Aave V3、Compound v3 都用代理 + 升级模式
- **新功能上线**:Uniswap V2 → V3 通过新部署 Logic + 升级
- **应急刹车**:发现漏洞时 admin 紧急升级到打补丁版

**核心思想:升级只改代码指针**

```
升级前:
  Proxy.implementation → Logic1 (foo() 写 "old")
  Proxy.storage:        words = ""
       ↓ proxy.upgrade(Logic2)
升级后:
  Proxy.implementation → Logic2 (foo() 写 "new")
  Proxy.storage:        words = ""  (不变!)
```

教学点:**storage 永远在 Proxy 里**,升级只是换 Logic 代码,数据不丢。

**与 44 课的差异**:
| 维度 | 44 课 (Proxy) | 45 课 (Upgrade) |
|------|--------------|----------------|
| Logic 数量 | 1 个 | 2 个(Logic1 + Logic2) |
| admin 字段 | 无 | 有(限制 upgrade 权限) |
| upgrade 函数 | 无 | `upgrade(newImpl)` |
| 教学焦点 | delegatecall 原理 | 升级前后行为变化 |

**升级风险:存储布局兼容性**

```
Logic1:  slot0=implementation, slot1=admin, slot2=words
Logic2:  slot0=implementation, slot1=admin, slot2=words     ✓ 兼容
Logic2': slot0=implementation, slot1=newField, slot2=admin  ✗ 不兼容(admin 位置变了)
```

新 Logic **只能往后加字段**,不能改老字段顺序/类型。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/SimpleUpgrade.sol` + `Logic1.sol` + `Logic2.sol` | 27 + 14 + 14 行 |
| **oz** | `src/oz/SimpleUpgrade.sol` | 11 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 命名占位。**生产环境**用 OZ `TransparentUpgradeableProxy`(46 课)或 `UUPSUpgradeable`(47 课),自带 EIP-1967 标准 + 完整鉴权。

## 4. 合约设计

### 4.1 SimpleUpgrade 状态

```solidity
contract SimpleUpgrade {
    address public implementation;   // 槽 0
    address public admin;             // 槽 1
    string public words;              // 槽 2
}
```

要点:**3 个 storage 字段**(与 Logic1/Logic2 完全一致),admin 控制升级权限。

### 4.2 fallback + delegatecall

```solidity
fallback() external payable {
    (bool success, bytes memory data) = implementation.delegatecall(msg.data);
}
```

教学点:
- 高级语法 `address.delegatecall(bytes)`:不需要写 assembly
- 返回值没用 `require(success)`:**故意省略,演示极简代理**(生产中必须 require)
- 没 `return(data)`:`fallback` 不支持非空返回值,所以测试中只能用 `(bool, bytes)` 拿数据

### 4.3 upgrade 函数

```solidity
function upgrade(address newImplementation) external {
    require(msg.sender == admin);
    implementation = newImplementation;
}
```

要点:
- `require(msg.sender == admin)`:鉴权,只有 admin 能升级
- 教学版无 timelock,生产中应加延迟(防 admin 作恶)

### 4.4 Logic1 / Logic2(储存布局对齐)

```solidity
contract Logic1 {
    address public implementation;   // 槽 0(占位)
    address public admin;             // 槽 1(占位)
    string public words;              // 槽 2
    
    function foo() public { words = "old"; }
}

contract Logic2 {
    address public implementation;   // 槽 0(占位)
    address public admin;             // 槽 1(占位)
    string public words;              // 槽 2
    
    function foo() public { words = "new"; }
}
```

教学点:**Logic 的前 3 个槽与 Proxy 完全一致**,否则 delegatecall 时会乱改 Proxy 的 implementation / admin。

### 4.5 业务流程

```
部署 logic1, logic2
部署 proxy(logic1)  ← 初始指向 Logic1
   ↓
proxy.call(foo()) → delegatecall → Logic1.foo() → proxy.words = "old"
   ↓
admin: proxy.upgrade(logic2)  ← 切换到 Logic2
   ↓
proxy.implementation 改成 logic2,但 proxy.words 仍是 "old"
   ↓
proxy.call(foo()) → delegatecall → Logic2.foo() → proxy.words = "new"
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/SimpleUpgrade.sol` + Logic1 + Logic2

#### SimpleUpgrade(27 行)
```solidity
contract SimpleUpgrade {
    address public implementation;
    address public admin;
    string public words;
    
    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }
    
    fallback() external payable {
        (bool success, bytes memory data) = implementation.delegatecall(msg.data);
    }
    
    function upgrade(address newImplementation) external {
        require(msg.sender == admin);
        implementation = newImplementation;
    }
}
```

要点:
- constructor 自动把部署方设为 admin
- 极简版,无完整事件 / 无 require(success) / 无重入保护(教学用)

#### Logic1(14 行)
```solidity
contract Logic1 {
    address public implementation;
    address public admin;
    string public words;
    
    function foo() public { words = "old"; }
}
```

#### Logic2(14 行,与 Logic1 唯一差别在 foo() 内容)
```solidity
contract Logic2 {
    address public implementation;
    address public admin;
    string public words;
    
    function foo() public { words = "new"; }
}
```

教学点:**Logic1 和 Logic2 必须有完全一致的存储布局**,只能改函数行为。

### 5.2 oz 实现 —— `src/oz/SimpleUpgrade.sol`

```solidity
import {SimpleUpgrade} from "../../src/raw/SimpleUpgrade.sol";

contract SimpleUpgradeOZ is SimpleUpgrade {
    constructor(address _implementation) SimpleUpgrade(_implementation) {}
}
```

要点:业务完全一致,本项目 oz 版只是命名占位。

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| 代码量 | 27+14+14=55 行 | 11 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 OZ `TransparentUpgradeableProxy`**:46 课讲(透明代理),解决"admin 调用混淆"问题;**OZ `UUPSUpgradeable`**:47 课讲(把 upgrade 放在 Logic 里,省 gas)。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/10_upgrade_governance/45_Upgrade
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── SimpleUpgrade.sol   # 27 行,代理+升级
│   ├── Logic1.sol           # 14 行,foo() = "old"
│   └── Logic2.sol           # 14 行,foo() = "new"
└── oz/SimpleUpgrade.sol     # OZ 版(继承 raw)
test/
├── raw/SimpleUpgrade.t.sol  # 6 个测试
└── oz/SimpleUpgrade.t.sol   # 2 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 8 个测试全部通过(raw 6 个 + oz 2 个)。

### 步骤 5:重点测试 —— 升级前后 storage 不变(`test/raw/SimpleUpgrade.t.sol`)

```solidity
function testWordsChangedByLogic1() public {
    address(proxy).call(abi.encodeWithSignature("foo()"));
    assertEq(proxy.words(), "old");                // Logic1 写入 "old"
    
    proxy.upgrade(address(logic2));
    assertEq(proxy.words(), "old");                // 升级后 words 仍是 "old"(关键!)
    
    address(proxy).call(abi.encodeWithSignature("foo()"));
    assertEq(proxy.words(), "new");                // Logic2 写入 "new"
}

function testOnlyAdminCanUpgrade() public {
    vm.prank(address(0x1234));
    vm.expectRevert();
    proxy.upgrade(address(logic2));                // 非 admin 调用 revert
}
```

教学点:
- **storage 在 Proxy**:Logic 升级后,proxy.words 数据不变
- `vm.prank(非 admin)` + `vm.expectRevert()`:校验权限控制

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS:
  - **raw**: `testInitialState`、`testProxyCallThroughLogic1`、`testUpgrade`、`testProxyCallAfterUpgrade`、`testOnlyAdminCanUpgrade`、`testWordsChangedByLogic1`
  - **oz**: `testInitialState`、`testProxyCallThroughLogic1`

## 8. 常见错误排查

### 错误 1:升级后旧数据丢失

- **常见原因**:新 Logic 的存储布局与老 Logic 不一致(如字段顺序变了)
- **解决步骤**:新 Logic **只能往后加字段**,绝不能改老字段顺序/类型
- **验证方式**:`testWordsChangedByLogic1` 验证升级后 words = "old" 保留

### 错误 2:任何人都能 upgrade

- **常见原因**:忘了 `require(msg.sender == admin)`
- **解决步骤**:upgrade 函数加权限校验
- **验证方式**:`testOnlyAdminCanUpgrade` 用 `vm.prank(0x1234)` 校验 revert

### 错误 3:upgrade 后 admin 字段被覆盖

- **常见原因**:新 Logic 的 admin 字段位置改了,导致 admin 被覆盖
- **解决步骤**:新 Logic 的 admin 必须在槽 1(与 Proxy 一致)
- **验证方式**:升级后调 `proxy.admin()` 应返回原 admin

### 错误 4:Logic 自带 constructor 没执行

- **常见原因**:Logic 的 constructor 在 Proxy 视角下不执行(delegatecall 不会调 constructor)
- **解决步骤**:把初始化逻辑放到 `initialize()` 函数,部署后 admin 主动调
- **验证方式**:用 OZ `Initializable` 库,防 initialize 被调多次

## 9. 本节总结

- Upgrade = Proxy + admin 鉴权的 `upgrade(newImpl)` 函数
- 核心:**升级只改代码指针,storage 永久存在 Proxy 里**
- 存储布局约束:新 Logic **只能往后加字段**,不能改老字段顺序/类型
- 教学版极简(无 require / 无 initialize / 无 timelock),生产用 OZ
- 与 44 课对比:本课在 Proxy 基础上加 upgrade 函数和 admin 权限
- 后续课程:46 课讲 TransparentProxy(防 admin 调用混淆),47 课讲 UUPS(把 upgrade 放在 Logic 里)
- 实战:Aave V3 / Compound v3 都用代理+升级,bug 修复无需迁移用户

## 10. 课后练习

### 练习 1
为 SimpleUpgrade 加 **升级事件**:
- 加 `event Upgraded(address indexed oldImpl, address indexed newImpl)`
- upgrade 函数中 emit
- 加测试:`vm.expectEmit` 校验事件被触发

### 练习 2
为 SimpleUpgrade 加 **timelock**:
- 加 `uint256 public upgradeDelay = 2 days;`
- 拆 upgrade 为两步:`proposeUpgrade(newImpl)` + `executeUpgrade()`,中间必须等 2 天
- 加测试:propose 后立即 execute 应 revert;`vm.warp +2 days` 后能 execute

### 练习 3(进阶)
基于 raw 的 SimpleUpgrade,实现 **多 admin 投票升级**:
- 加 `address[] public admins;` 和 `uint256 public threshold = 2;`
- 拆 upgrade 为 `voteUpgrade(newImpl)`,达 threshold 自动执行
- 加测试:1 admin 投票不升级,2 admin 投票才升级
- 提示:这是 Gnosis Safe 多签升级的简化版
