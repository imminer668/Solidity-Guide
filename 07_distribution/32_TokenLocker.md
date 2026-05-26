# 第 32 课:TokenLocker —— 代币锁仓合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么要把项目方代币锁仓一段时间(尤其在 DEX 上线前)"
- 自己手写一个最小可用的 TokenLocker(raw 实现)
- 用 OpenZeppelin 的 ERC20 类型搭一个等价的 TokenLocker(oz 实现)
- 区分 TokenLocker(一次性释放)和 TokenVesting(线性释放)
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币
- 第 31 课:TokenVesting(本课是它的"极简版"—— 一次性释放)
- 第 16 课:时间戳与区块(`block.timestamp` / `vm.warp`)

## 3. 先讲结论

**TokenLocker(代币锁仓)是把代币锁在合约里一段时间后,到期一次性释放给受益人**。典型场景:
- **DEX 上线前**:项目方把流动性池子 LP token 锁仓 6 个月,证明"我不会跑路"
- **空投领取**:某些项目方代币要求 1 年锁仓期,到期才能领
- **众筹退款期**:募集期结束 N 天后,未达标的众筹才能退款

**为什么不直接写一句"半年后打款"?**
- 写死在合约里,到期**任何人都能触发释放**,不依赖项目方主动配合
- 资金在合约里,**项目方也拿不走**,只有时间到了受益人才能取
- 锁仓期内任何人调 `release()` 都会 revert —— 规则清晰

**与 TokenVesting(31 课)的关键区别**:

| 维度 | TokenVesting | TokenLocker(本课) |
|------|-------------|-------------------|
| 释放模式 | 线性插值(每时每刻都能领累计的) | **一次性释放**(到期全领) |
| 公式 | `vested = total * (now-start) / duration` | `now >= start + lockTime` |
| 累计计数器 | `erc20Released[token]` | 不需要(只发一次) |
| 复杂度 | 中(分段函数) | 极简(单点释放) |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/TokenLocker.sol` | ~42 行 |
| **oz** | `src/oz/TokenLocker.sol` | ~41 行 |

> 注:本项目两版的源码几乎完全一致,差别只在 IERC20 的 import 路径(本地 vs OZ)。生产环境也常手写,因 OZ 没有现成的 Locker 合约。

## 4. 合约设计

### 4.1 状态

```solidity
IERC20 public immutable token;        // 锁仓的 token
address public immutable beneficiary; // 受益人
uint256 public immutable lockTime;    // 锁仓秒数
uint256 public immutable startTime;   // 部署时间(锁定)
```

四个 `immutable` 字段:**部署后终身不可改**。这是 locker 的安全基石。

### 4.2 两个事件

```solidity
event TokenLockStart(address indexed beneficiary, address indexed token, uint256 startTime, uint256 lockTime);
event Release(address indexed beneficiary, address indexed token, uint256 releaseTime, uint256 amount);
```

- `TokenLockStart` 部署时触发,记录"谁锁了什么、锁多久"
- `Release` 释放时触发,记录"谁在什么时间领了多少"

### 4.3 业务流程

```
部署:
  constructor(token, beneficiary, lockTime)
  startTime = block.timestamp
   ↓
项目方:把 N 个 token 转给 locker 合约
   ↓
锁仓期内:任何 release() 调用 → revert("current time is before release time")
   ↓
时间到:startTime + lockTime 之后,任何人都能调 release()
  amount = token.balanceOf(this)  // 一次性取走全部
  transfer(beneficiary, amount)
  emit Release(...)
```

### 4.4 为什么 release 不限 msg.sender

```
TokenLocker 的 release() 没有 require(msg.sender == beneficiary)
  → 任何人都能调
  → 反正钱进 beneficiary,谁触发都一样
  → 好处:如果 beneficiary 是合约/丢失私钥的 EOA,别人仍可代为触发
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/TokenLocker.sol`

#### constructor
```solidity
constructor(IERC20 token_, address beneficiary_, uint256 lockTime_) {
    require(lockTime_ > 0, "TokenLock: lock time should greater than 0");
    token = token_;
    beneficiary = beneficiary_;
    lockTime = lockTime_;
    startTime = block.timestamp;
    emit TokenLockStart(beneficiary_, address(token_), block.timestamp, lockTime_);
}
```

要点:
- `lockTime_ > 0` 防止"零秒锁仓"等无效输入
- 部署时立刻 emit `TokenLockStart` 事件,链上能搜到"何时锁的、锁什么、锁多久"
- 三个字段都是 `immutable`,存在 bytecode 里,读起来比 storage 便宜(无 SLOAD)

#### release
```solidity
function release() public {
    require(block.timestamp >= startTime + lockTime, "TokenLock: current time is before release time");

    uint256 amount = token.balanceOf(address(this));
    require(amount > 0, "TokenLock: no tokens to release");

    token.transfer(beneficiary, amount);
    emit Release(msg.sender, address(token), block.timestamp, amount);
}
```

要点:
- **时间校验在前**:`block.timestamp >= startTime + lockTime` —— 锁仓期内任何人调都 revert
- **余额校验在后**:`amount > 0` 防止"合约没充值就 release"或"重复 release 第二次时金额为 0"
- 用 `token.balanceOf(this)` 而非存储 amount,这样中途项目方**可以继续追加充值**(每多投,到时候就多领)
- 不限 `msg.sender`,任何人都能触发

### 5.2 oz 实现 —— `src/oz/TokenLocker.sol`

```solidity
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ... 业务逻辑与 raw 完全一致
```

唯一差别:IERC20 改用 OZ 版本。

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| IERC20 来源 | `src/raw/IERC20.sol`(本地) | `@openzeppelin/contracts/.../IERC20.sol` |
| 业务逻辑 | 完全一致 | 完全一致 |
| 代码量 | ~42 行 | ~41 行 |
| 适用 | 学原理、想贴近 token 操控细节 | 想要 OZ 一致性 |

**本项目 oz 版没有"额外引入 OZ 库"**,只是 import 路径换了 OZ IERC20。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/32_TokenLocker
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── IERC20.sol
│   ├── ERC20.sol             # 24 课的 raw ERC20
│   └── TokenLocker.sol       # 原生 TokenLocker
└── oz/
    ├── ERC20Minter.sol
    └── TokenLocker.sol       # OZ 版 TokenLockerOZ
test/
├── raw/TokenLocker.t.sol
└── oz/TokenLocker.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 6 个测试全部通过(raw 3 个 + oz 3 个)。

### 步骤 5:重点测试 —— 锁仓与释放(`test/raw/TokenLocker.t.sol`)

```solidity
function setUp() public {
    token = new ERC20();
    locker = new TokenLocker(token, beneficiary, 100);  // 锁仓 100s
    token.mint(address(locker), 10000);                // 充值 10000
}

function testCannotReleaseBeforeLockTime() public {
    vm.expectRevert("TokenLock: current time is before release time");
    locker.release();   // setUp 之后没 warp,仍在锁仓期内
}

function testReleaseAfterLockTime() public {
    vm.warp(block.timestamp + 101);     // 跳 101 秒,超过 100 秒锁仓期
    locker.release();
    assertEq(token.balanceOf(beneficiary), 10000);
}
```

教学点:
- `vm.expectRevert("字符串")` 必须在调用前设置,且**字符串必须完全匹配** revert 原因
- 锁仓校验只用了 `block.timestamp`(秒级),不依赖 block.number
- 用 `+101` 而非 `+100`,因为 100s 整点时 `block.timestamp == startTime + lockTime` 满足条件,但留 1s buffer 更稳

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 6 个测试全部 PASS:
  - **raw**: `testInitialState`、`testCannotReleaseBeforeLockTime`、`testReleaseAfterLockTime`
  - **oz**: `testInitialState`、`testCannotReleaseBeforeLockTime`、`testReleaseAfterLockTime`

## 8. 常见错误排查

### 错误 1:`release()` 报 "current time is before release time"

- **常见原因**:没到 `startTime + lockTime`
- **解决步骤**:`vm.warp(block.timestamp + lockTime + 1)` 跳到锁仓期之后
- **验证方式**:`testReleaseAfterLockTime` 用 `vm.warp(block.timestamp + 101)`

### 错误 2:`release()` 报 "no tokens to release"

- **常见原因**:合约没充值(余额为 0)或已 release 过一次(余额为 0)
- **解决步骤**:setUp 中 `token.mint(address(locker), amount)`,或部署后由项目方 transfer
- **验证方式**:`setUp` 末尾 `token.mint(address(locker), 10000)` 是关键

### 错误 3:用 `block.number` 算时间,发现测试总不通过

- **常见原因**:Locker 用 `block.timestamp` 不是 `block.number`,二者不能混
- **解决步骤**:统一用 `block.timestamp` 和 `vm.warp` 控制
- **验证方式**:OZ 的 `VestingWallet` 也是 timestamp-based;少数项目用 block-based(早期 Aragon)

### 错误 4:想分批释放(每月领 1/24),发现做不到

- **常见原因**:TokenLocker 是"一次性释放",没有累计/差量逻辑
- **解决步骤**:用 TokenVesting(31 课)或加 cliff 改造
- **验证方式**:本合约 `amount = token.balanceOf(this)` 把所有余额一次转走,无法分批

## 9. 本节总结

- TokenLocker = **到期一次性释放**,极简模式
- 四个 `immutable` 字段(token / beneficiary / lockTime / startTime)部署锁定
- `release()` 两个校验:**时间到** + **金额 > 0**
- 不限 `msg.sender`,任何人都能触发,反正钱进 beneficiary
- 与 TokenVesting(31 课)对比:线性 vs 一次性
- `vm.expectRevert("字符串")` 是测试 revert 的标准 Foundry 写法
- 实战场景:DEX 上线前的 LP 锁仓、空投锁仓期、众筹退款期

## 10. 课后练习

### 练习 1
为 TokenLocker 加 **"先到先得,一次性"** 进阶版:
- 加 `mapping(address => bool) public claimed;` 记录"多受益人谁领过"
- 把 `beneficiary` 改为 `address[] public beneficiaries;`(白名单)
- `release()` 改为 `releaseFor(address recipient)`,只有 `claimed[recipient] == false` 且在白名单内的人能领一次
- 加测试:Alice 领 5000,Bob 领 5000,Alice 二次 release 应 revert

### 练习 2
为 TokenLocker 加 **"提前解锁但有惩罚"** 模式:
- 加 `function earlyRelease() public` 立即释放全部,但扣 10% 罚款归项目方
- 项目方地址作为 constructor 参数传入
- 加测试:未到 lockTime 时 Alice 调 earlyRelease,Alice 拿 9000,owner 拿 1000

### 练习 3(进阶)
基于 raw 的 TokenLocker,实现 **"按比例多签解锁"**:
- 加 `address[] public guardians`(多签成员)
- 加 `mapping(address => bool) public approvals`(guardian -> 批准过)
- 加 `uint256 public approvalThreshold = 2`
- `release()` 必须先收集 N 个 guardian 的 approve,达到阈值才能释放
- 加测试:3 个 guardians,A 调 approve,B 调 approve,达到 2/3 阈值后,任何人都能调 release
