# 第 33 课:Timelock —— 时间锁延迟执行合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 DAO / 治理合约都要用 Timelock 包裹一层"
- 自己手写一个支持 queue / execute / cancel 三段式的 Timelock(raw 实现)
- 理解 `getTxHash` 工具函数在"任意交易参数 → 唯一 key"的设计意图
- 区分 Timelock(本课,通用执行延迟)与 TokenLocker(32 课,代币锁仓)
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 32 课:TokenLocker(都是时间相关合约,但本课是"通用执行延迟"而不是"代币释放")
- 第 18 课:ABI 编码(`abi.encode` / `abi.encodePacked` 是构造 calldata 的关键)
- 第 17 课:合约调用(`address.call{value:}` 执行任意交易)
- 第 12 课:Modifier(`onlyOwner` / `onlyTimelock` 是 Timelock 权限核心)

## 3. 先讲结论

**Timelock(时间锁)是"延迟执行"机制 —— 任何交易都必须先排队(queue),等 `delay` 秒之后才能执行(execute)**。典型场景:
- **Compound 治理**:提案通过后必须等 2 天才能执行,给社区反应时间
- **OpenZeppelin Governor**:官方就基于 TimelockController
- **项目方多签钱包**:不是多签批准后立即执行,而是批准 + delay 后才能执行
- **Tornado Cash 升级合约**:升级前留出"反对窗口"

**为什么 DAO 必须用 Timelock?**
- 提案通过 → 立即执行的"闪电治理攻击":黑客买大量投票权通过提案,马上掏空国库
- 加了 Timelock:**通过后必须等 N 天**,社区有时间发现恶意提案、撤资、撤销
- 这是"善意治理"的最后一道防线

**核心三段式生命周期**:

```
queueTransaction(...)  ← 管理员/治理合约:排队,设置 eta = now + delay
       ↓
[等 delay 秒]           ← 任何人都能等
       ↓
executeTransaction(...) ← 任何人都能调(实际执行)
       ↓ (如果 [eta, eta+GRACE_PERIOD] 内未执行)
   作废                 ← 之后调 executeTransaction 也会 revert
```

**与 TokenLocker(32 课)的关键区别**:

| 维度 | TokenLocker | Timelock(本课) |
|------|-------------|----------------|
| 目的 | 代币一次性释放 | 任意交易的延迟执行 |
| 操作对象 | ERC20 token | 任意 target 合约 |
| 时间到后 | 自动可领 | 必须有人调 execute |
| 灵活性 | 单一功能 | 通用"管理执行器" |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/Timelock.sol` | ~111 行 |
| **oz** | `src/oz/Timelock.sol` | ~10 行(继承 raw) |

> 注:本项目 oz 版只继承 raw,加个 `TimelockOZ` 后缀。**生产环境推荐 OZ 官方 `TimelockController.sol`**,带角色访问控制(Proposer / Executor / Admin),比本课的"单一 admin"更安全。

## 4. 合约设计

### 4.1 状态

```solidity
address public admin;                 // 唯一管理员
uint public constant GRACE_PERIOD = 7 days;  // 宽限期:eta + 7天 之内必须执行,否则作废
uint public delay;                    // 延迟时间(秒)

mapping(bytes32 => bool) public queuedTransactions;  // txHash → 是否已排队
```

### 4.2 四个事件

```solidity
event QueueTransaction(...);      // 排队
event ExecuteTransaction(...);    // 执行
event CancelTransaction(...);     // 取消
event NewAdmin(address newAdmin); // 移交管理员
```

### 4.3 三个核心 modifier

```solidity
modifier onlyOwner() { require(msg.sender == admin, "..."); _; }       // 仅 admin 可调 queue/cancel
modifier onlyTimelock() { require(msg.sender == address(this), "..."); _; }  // 仅 Timelock 自己可调 changeAdmin
```

教学点:**`onlyTimelock` 是 Timelock 的灵魂 modifier** —— `changeAdmin` 必须由 Timelock 自己调,意味着新 admin 的设置也要走"排队-等-执行"流程,管理员移交也是延迟生效的。

### 4.4 业务流程

```
管理员:queueTransaction(target, value, sig, data, eta)
  → 计算 txHash = keccak256(target, value, sig, data, eta)
  → require(eta >= now + delay)
  → queuedTransactions[txHash] = true
  → emit QueueTransaction
       ↓
[等 delay 秒,eta 时刻到来]
       ↓
任何人都能调:executeTransaction(target, value, sig, data, eta)
  → 计算 txHash
  → require(queuedTransactions[txHash])
  → require(now >= eta)
  → require(now <= eta + GRACE_PERIOD)
  → queuedTransactions[txHash] = false
  → 拼 calldata = sig.empty ? data : bytes4(keccak256(sig)) ++ data
  → target.call{value: value}(calldata)
  → require(success)
  → emit ExecuteTransaction
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/Timelock.sol`

#### getTxHash:把交易参数 hash 成唯一 key
```solidity
function getTxHash(
    address target, uint value, string memory signature, bytes memory data, uint executeTime
) public pure returns (bytes32) {
    return keccak256(abi.encode(target, value, signature, data, executeTime));
}
```

要点:
- `pure` 函数不上链、读不到链上状态
- `abi.encode` 把所有参数按 ABI 规则打包,然后 keccak256 出一个唯一 hash
- 只要五个参数中任何一个不同(包括 eta 时刻不同),hash 就不同 → 同一交易不同 eta 是不同记录
- 这个 hash 就是 `queuedTransactions` 的 key,也是事件里的 `txHash`

#### queueTransaction:排队
```solidity
function queueTransaction(...) public onlyOwner returns (bytes32) {
    require(executeTime >= getBlockTimestamp() + delay, "Timelock::queueTransaction: ...");
    bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
    queuedTransactions[txHash] = true;
    emit QueueTransaction(txHash, target, value, signature, data, executeTime);
    return txHash;
}
```

要点:
- `onlyOwner` 限制仅 admin 可排队(生产中往往改成治理合约)
- `executeTime >= now + delay` 防止"立即执行"绕过延迟
- 返回 txHash 方便调用方/前端记录"这笔排队是哪个"

#### executeTransaction:延迟后执行
```solidity
function executeTransaction(...) public payable onlyOwner returns (bytes memory) {
    bytes32 txHash = getTxHash(target, value, signature, data, executeTime);
    require(queuedTransactions[txHash], "...hasn't been queued.");
    require(getBlockTimestamp() >= executeTime, "...hasn't surpassed time lock.");
    require(getBlockTimestamp() <= executeTime + GRACE_PERIOD, "...is stale.");
    
    queuedTransactions[txHash] = false;  // 先清标记(CEI 模式)
    
    bytes memory callData;
    if (bytes(signature).length == 0) {
        callData = data;  // 没签名 → 直接用 data
    } else {
        callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);  // 拼出 4 字节 selector + 参数
    }
    
    (bool success, bytes memory returnData) = target.call{value: value}(callData);
    require(success, "...execution reverted.");
    
    emit ExecuteTransaction(txHash, target, value, signature, data, executeTime);
    return returnData;
}
```

教学重点:
- **三段 require**:queued + 时间到 + 未过期
- **GRACE_PERIOD = 7 days**:超过 `eta + 7天` 就作废,防止有人"忘了执行"长期占位
- **先清标记再调用**(CEI):虽然 Timelock 不会重入到自身(因为 `onlyOwner`),但好习惯
- **空 signature 分支**:支持两种 calldata —— 带函数签名(普通调用)或纯 data(底层调用,fallback 接收)
- **`payable`** + `value` 字段:可以带 ETH 一起执行(从 Timelock 余额扣)
- **forward returnData**:把 target 的返回值原样返回,方便前端解析

#### cancelTransaction:撤销
```solidity
function cancelTransaction(...) public onlyOwner {
    bytes32 txHash = getTxHash(...);
    require(queuedTransactions[txHash], "...hasn't been queued.");
    queuedTransactions[txHash] = false;
    emit CancelTransaction(...);
}
```

要点:
- admin 发现排队项有问题(目标合约有漏洞 / 提案被否决)可主动撤销
- 撤销后即使到 eta 也无法 execute(`queuedTransactions[txHash] == false` 触发 require)
- 撤销不消耗 gas 之外的资源,只是清标记

#### changeAdmin:移交管理员(自递归延迟)
```solidity
function changeAdmin(address newAdmin) public onlyTimelock {
    admin = newAdmin;
    emit NewAdmin(newAdmin);
}
```

教学点:`onlyTimelock` modifier 让 admin 移交**也要走 queue → execute** 流程。也就是说"现 admin 把自己替换掉"也是延迟生效的,这是 Timelock 的精髓 —— 任何特权操作都延迟,防"深夜政变"。

### 5.2 oz 实现 —— `src/oz/Timelock.sol`

```solidity
import {Timelock} from "../../src/raw/Timelock.sol";

contract TimelockOZ is Timelock {
    constructor(uint delay_) Timelock(delay_) {}
}
```

要点:
- **直接继承 raw**:`TimelockOZ` 只是 raw 的"重命名版"
- 文件名 `Timelock.sol` 是兼容 OZ 命名约定(同目录下没有两个同名合约冲突)
- 业务行为完全等价
- **生产用 OZ 官方 `TimelockController.sol`**(带角色):`PROPOSER_ROLE` / `EXECUTOR_ROLE` / `CANCELLER_ROLE` / `ADMIN_ROLE`

### 5.3 对照看 —— raw vs oz

| 维度 | raw Timelock | oz TimelockOZ |
|------|--------------|---------------|
| 业务逻辑 | 自写完整 | 继承 raw |
| 权限模型 | 单一 admin | 单一 admin(继承) |
| 代码量 | ~111 行 | ~10 行 |
| 适用 | 学原理 | 想用 OZ 命名风格,但本项目无 OZ 库 |

**注意**:`TimelockOZ` 在本项目里没有引入 OZ 库,只是 import raw 改名。**生产环境**请使用 `@openzeppelin/contracts/governance/TimelockController.sol`。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/33_Timelock
```

### 步骤 2:查看文件结构

```
src/
├── raw/Timelock.sol          # 原生 Timelock(完整实现)
└── oz/Timelock.sol           # 继承 raw,改个名
test/
├── raw/Timelock.t.sol
└── oz/Timelock.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 9 个测试全部通过(raw 6 个 + oz 3 个)。

### 步骤 5:重点测试 —— 延迟执行(`test/raw/Timelock.t.sol`)

```solidity
function testExecuteAfterDelay() public {
    uint256 executeTime = block.timestamp + 100;
    bytes32 txHash = timelock.queueTransaction(
        address(1), 0, "test()", "", executeTime
    );
    vm.warp(executeTime + 1);
    timelock.executeTransaction(address(1), 0, "test()", "", executeTime);
    assertTrue(!timelock.queuedTransactions(txHash));  // 已清标记
}
```

教学点:
- `address(1)` 是 EOA(测试用占位),`call("test()")` 在 EOA 上成功(EOA 接收任何 call 都返回 success)
- `vm.warp(executeTime + 1)` 跳过 delay,刚到 eta 时刻
- 调用前后 `queuedTransactions[txHash]` 从 true 变 false,验证"已清标记"

```solidity
function testCannotExecuteBeforeTime() public {
    uint256 executeTime = block.timestamp + 200;
    timelock.queueTransaction(address(1), 0, "test()", "", executeTime);
    vm.expectRevert("Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
    timelock.executeTransaction(address(1), 0, "test()", "", executeTime);
}
```

教学点:`vm.expectRevert` 必须在调用前,字符串必须完全匹配 revert 原因。

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 9 个测试全部 PASS:
  - **raw**: `testInitialState`、`testQueueTransaction`、`testCannotExecuteBeforeTime`、`testExecuteAfterDelay`、`testCancelTransaction`、`testGetTxHash`
  - **oz**: `testInitialState`、`testQueueTransaction`、`testExecuteAfterDelay`

## 8. 常见错误排查

### 错误 1:`executeTransaction` 报 "hasn't surpassed time lock"

- **常见原因**:`block.timestamp < executeTime`,还没到 eta
- **解决步骤**:`vm.warp(executeTime + 1)`,跳到 eta 之后
- **验证方式**:`testExecuteAfterDelay` 用 `executeTime + 1`

### 错误 2:`executeTransaction` 报 "is stale"

- **常见原因**:`block.timestamp > executeTime + GRACE_PERIOD`(本课 7 天),过期了
- **解决步骤**:测试中用 `vm.warp` 跳到 `[eta, eta+7days]` 区间内,而不是更后
- **验证方式**:`GRACE_PERIOD = 7 days`,超过就 revert

### 错误 3:非 admin 调 `queueTransaction` 报 "Caller not admin"

- **常见原因**:`msg.sender != admin`,本课 admin 是单一地址
- **解决步骤**:`vm.prank(admin); timelock.queueTransaction(...)`;或者测试本身在 setUp 时 `admin = address(this)`,因为 msg.sender 默认是测试合约
- **验证方式**:`testQueueTransaction` 不需 prank,因为 setUp 之后 `address(this)` 就是 admin

### 错误 4:目标 call 失败,执行 revert

- **常见原因**:`target.call{value: value}(callData)` 返回 false —— target 合约 revert、没 fallback、gas 不足
- **解决步骤**:检查 target 合约 / 调大 gas / 把 signature 拼对(selector 用 `bytes4(keccak256(sig))`)
- **验证方式**:用 `console.log` 打印 calldata,或者用 `bytes4(keccak256("test()"))` 验证 selector

## 9. 本节总结

- Timelock 是 DAO / 治理合约的"延迟执行"机制,防闪电治理攻击
- 三段式:**queueTransaction → [等 delay] → executeTransaction**,可 cancelTransaction
- `GRACE_PERIOD` 防止"长期占位"超过 eta+7天就作废
- `getTxHash` 把五参数 hash 成唯一 key,任何参数不同就是不同交易
- `target.call{value: value}(calldata)` 执行任意交易,带可选 ETH
- `onlyTimelock` modifier 让 `changeAdmin` 也走延迟,管理员移交是延迟生效的
- 与 TokenLocker 对比:Timelock 是通用"管理执行器",TokenLocker 是单一"代币释放"
- 生产环境用 OZ `TimelockController`(带角色访问控制,比单一 admin 安全)

## 10. 课后练习

### 练习 1
为 Timelock 加 **执行失败时回滚状态**:
- 当 `target.call` 失败时,**把 `queuedTransactions[txHash]` 还原回 true**(让用户重试)
- 加测试:目标合约故意 revert,executeTransaction 应回滚标记,二次 execute 仍可能成功

### 练习 2
为 Timelock 加 **多签名管理员**:
- 把 `admin` 改成 `address[] public admins`(数组)+ `mapping(address => bool) public isAdmin`
- `queueTransaction` 需要 ≥2 个 admin 签名才能排队
- `executeTransaction` 任一 admin 都能调(因为已通过排队校验)
- 加测试:Alice 单独调应 revert,Alice + Bob 各自 approve 后应成功

### 练习 3(进阶)
基于 raw Timelock,实现 **可升级 Timelock(可调 delay)**:
- 加 `function updateDelay(uint newDelay) public onlyTimelock`
- 改动要走 queue → execute 流程(用 `onlyTimelock` modifier)
- 校验:`newDelay >= MIN_DELAY` 且 `newDelay <= MAX_DELAY`(如 1 天 ≤ delay ≤ 30 天)
- 加测试:把 delay 从 100 改到 200,改完后再排队的交易 eta 必须 ≥ now + 200
- 提示:这就是 OZ `TimelockController.updateDelay` 的实现思路
