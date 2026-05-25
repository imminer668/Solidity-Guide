# 第 31 课:TokenVesting —— 代币线性释放合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么项目方要给团队/投资人锁定代币,然后按时间慢慢释放"
- 自己手写一个最小可用的 TokenVesting(raw 实现)
- 用 OpenZeppelin 的 ERC20 类型搭一个等价的 TokenVesting(oz 实现)
- 理解 `vestedAmount` 公式如何在"线性时间"下正确计算当前可领
- 用 Foundry `vm.warp` 推进时间,跑通全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币(`balanceOf` / `transfer` 是 vesting 操作 token 的基础)
- 第 30 课:PaymentSplit(`totalReceived = balance + released` 的"累计"思路延续到 vesting)
- 第 16 课:时间戳与区块(`block.timestamp` / `vm.warp` 控制时间)

## 3. 先讲结论

**TokenVesting(代币线性释放)是项目方"按时间表"把代币交给团队/投资人/国库的合约**。典型场景:
- 团队代币:4 年线性释放,1 年 cliff(锁定期)
- 投资人:分 3 年释放,每 6 个月领一次
- 顾问:服务 2 年,按月释放

**为什么不直接打款,要单独写个合约?**
- 写死在合约里,**任何人都能验证释放规则**(链上透明)
- 项目方跑路后,钱还在合约里,按规则释放
- 受益人**自助 pull**,项目方不需要主动操作

**核心公式**(线性的灵魂):

```
vestedAmount(token, now) = totalAllocation * (now - start) / duration
```

其中:
- `totalAllocation = token.balanceOf(this) + erc20Released[token]` —— "原本该释放的总量"
- 0 ≤ 比例 ≤ 1,正好是"时间走过的比例"

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/TokenVesting.sol` | ~42 行 |
| **oz** | `src/oz/TokenVesting.sol` | ~41 行 |

> 注:本项目两版的源码几乎完全一致 —— 都参考 OZ `VestingWallet` 的精简版。生产环境推荐直接用 OZ `@openzeppelin/contracts/finance/VestingWallet.sol`(支持 ETH + ERC20 双通道、自带 cliff 概念)。

## 4. 合约设计

### 4.1 状态

```solidity
mapping(address => uint256) public erc20Released;   // 某种 token 已发放累计
address public immutable beneficiary;                // 受益人(部署时锁定,不可改)
uint256 public immutable start;                      // 释放起点(部署时的 block.timestamp)
uint256 public immutable duration;                   // 释放周期(秒)
```

三个 `immutable`:**部署后终身不可改**。这是 vesting 的安全基石 —— 受益人/起点/周期不能中途被改。

### 4.2 事件

```solidity
event ERC20Released(address indexed token, uint256 amount);
```

只发一个事件,简洁。

### 4.3 业务流程

```
部署:
  constructor(beneficiary, durationSeconds)
  beneficiary = msg.sender/beneficiary
  start = block.timestamp      ← 起点锁定
  duration = durationSeconds
   ↓
项目方:把 N 个 token 转给 vesting 合约
   ↓
任意时刻:任何人都可以调 release(token)
  vested = totalAllocation * (now - start) / duration
  releasable = vested - erc20Released[token]
  转账 releasable 给 beneficiary
  erc20Released[token] += releasable
   ↓
时间走完 duration:vested = totalAllocation,可一次领完剩余
```

### 4.4 线性释放 vs 累计公式

```
PaymentSplit(30 课):总收款 × 份额占比
TokenVesting(本课):总配额 × 时间占比

PaymentSplit 是"按人分账",TokenVesting 是"按时间分账"。
两者都用 balance + released 反推 totalAllocation,本质同源。
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/TokenVesting.sol`

```solidity
constructor(address beneficiaryAddress, uint256 durationSeconds) {
    require(beneficiaryAddress != address(0), "...");
    beneficiary = beneficiaryAddress;
    start = block.timestamp;
    duration = durationSeconds;
}
```

要点:
- `start` 用 `block.timestamp` 在 constructor 中取值,部署时刻就是释放起点
- `duration` 是秒数(常见值:`180 days` / `4 * 365 days` / `31536000` 一年)
- `immutable` 字段存 bytecode,读起来比 storage 便宜

### 5.2 release —— 受益人主动领

```solidity
function release(address token) public {
    uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
    require(releasable > 0, "No tokens to release");

    erc20Released[token] = ... + releasable;  // 注:源码这里用 += 但写成两行,实际就是累加
    emit ERC20Released(token, releasable);
    IERC20(token).transfer(beneficiary, releasable);
}
```

要点:
- **任何人都可以代某个受益人调** —— 反正钱进 beneficiary
- 用 `vestedAmount(now)` 而不是自己算,保证规则一致
- `releasable = vested - released` 是"累计已释放"差量 —— 跟 PaymentSplit 一样的"差量领"模式

### 5.3 vestedAmount —— 累计模型的灵魂

```solidity
function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
    uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];

    if (timestamp < start) {
        return 0;                                          // 还没到 start → 一分没释放
    } else if (timestamp > start + duration) {
        return totalAllocation;                            // 超过 duration → 全部释放
    } else {
        return (totalAllocation * (timestamp - start)) / duration;  // 线性插值
    }
}
```

举个栗子(duration = 100,totalAllocation = 10000):
```
t = start  :vested = 10000 * 0 / 100 = 0
t = start+25:vested = 10000 * 25/100 = 2500
t = start+50:vested = 10000 * 50/100 = 5000
t = start+75:vested = 10000 * 75/100 = 7500
t = start+100:vested = 10000 * 100/100 = 10000
t > start+100:vested = 10000(封顶)
```

教学点:
- 三段式 `if/else if/else` 是最清晰的"分段函数"写法
- `totalAllocation = balance + released` 的妙处:**不用单独记录"总配额"**,直接从合约余额反推
  - 部署时:balance = 10000,released = 0,totalAllocation = 10000
  - 领一半后:balance = 5000,released = 5000,totalAllocation = 10000(不变)
- 整数除法有精度损失,但对小额不在意;大额用 wei 精度足够

### 5.4 oz 实现 —— `src/oz/TokenVesting.sol`

```solidity
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// ... 业务逻辑与 raw 完全一致
```

要点:
- 唯一差别:`IERC20` 改用 OZ 版本(节省 1 个本地 IERC20.sol 文件)
- 业务代码完全一致,合约名 `TokenVestingOZ`

### 5.5 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| IERC20 来源 | `src/raw/IERC20.sol`(本地) | `@openzeppelin/contracts/.../IERC20.sol` |
| 业务逻辑 | 完全一致 | 完全一致 |
| 代码量 | ~42 行 | ~41 行 |
| 部署时 | import 一致 | import 路径换 OZ |

**本项目 oz 版没有"额外引入 OZ 库"**,只是把同样代码用 `OZ` 后缀命名,作为占位对比。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/31_TokenVesting
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── IERC20.sol
│   ├── ERC20.sol             # 24 课的 raw ERC20(带无权限 mint)
│   └── TokenVesting.sol      # 原生 TokenVesting
└── oz/
    ├── ERC20Minter.sol       # 暴露 mint 的薄壳
    └── TokenVesting.sol      # OZ 版 TokenVestingOZ
test/
├── raw/TokenVesting.t.sol
└── oz/TokenVesting.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 7 个测试全部通过(raw 4 个 + oz 3 个)。

### 步骤 5:重点测试 —— 线性释放(`test/raw/TokenVesting.t.sol`)

```solidity
function setUp() public {
    token = new ERC20();
    vesting = new TokenVesting(beneficiary, 100);  // duration = 100s
    token.mint(address(vesting), 10000);          // 给 vesting 充值 10000
}

function testRelease() public {
    vm.warp(block.timestamp + 50);                 // 时间走 50s(50% 周期)
    vesting.release(address(token));                // 受益人(或任何人)调 release
    assertEq(token.balanceOf(beneficiary), 5000);  // 应得 10000 * 50/100 = 5000
}
```

教学点:
- `vm.warp(t)` 推进 `block.timestamp` 到 `t` —— Foundry 控制时间的关键 cheatcode
- 不用 `vm.prank`,因为 release 不限制 msg.sender(任何人都能调,反正钱进 beneficiary)
- 整数除法:`10000 * 50 / 100 = 5000`(整除,精度无损)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 7 个测试全部 PASS:
  - **raw**: `testInitialState`、`testVestedAmountAtStart`、`testVestedAmountAfterDuration`、`testRelease`
  - **oz**: `testInitialState`、`testVestedAmountAfterDuration`、`testRelease`

## 8. 常见错误排查

### 错误 1:`release` 报 "No tokens to release"

- **常见原因**:还没到 `start` 时刻(几乎不会发生,因 start 就在部署时),或 `now - start` 太小,或已领完
- **解决步骤**:用 `vm.warp` 推进时间,再 release;或检查 erc20Released 是否已等于 totalAllocation
- **验证方式**:`testRelease` 用 `vm.warp(block.timestamp + 50)` 推进到 50% 周期

### 错误 2:整数除法精度损失

- **常见原因**:`(totalAllocation * elapsed) / duration` 当 numerator 不能被 duration 整除时,会丢精度
- **解决步骤**:duration 取大点的秒数(如 4 年 = `4 * 365 days`),误差 < 1 wei;或用 OZ 的 SafeMath
- **验证方式**:`testRelease` 中 10000 * 50 / 100 = 5000(整除,无损);改成 10001 * 33 / 100 = 3300.33 → 3300,丢 1 wei

### 错误 3:想加 cliff(锁定期)找不到

- **常见原因**:本课 TokenVesting 是最简线性版,**无 cliff 概念**
- **解决步骤**:自己改造 `vestedAmount`,加 `if (timestamp < start + cliff) return 0;`,或用 OZ `VestingWallet`(已内置)
- **验证方式**:看 OZ `VestingWallet` 源码,了解 cliff 怎么实现

### 错误 4:部署后想改 beneficiary,改不了

- **常见原因**:`beneficiary` 是 `immutable`,部署时锁定终身
- **解决步骤**:重新部署一个,或用 proxy 模式把 beneficiary 移到 storage slot(复杂)
- **验证方式**:这是设计选择 —— 防止项目方中途偷换受益人

## 9. 本节总结

- TokenVesting 用**累计 + 线性插值**:`vested = totalAllocation * (now - start) / duration`
- `totalAllocation = balance + released` 自动反推总配额,不用显式存
- `release` 任何人都能调,差量领取(`vested - released`)
- `beneficiary` / `start` / `duration` 三个 `immutable` 字段,**部署后终身不可改**
- 配合 `vm.warp` 测试时间相关的逻辑
- 整数除法有精度损失,大额用 wei 精度无忧
- 生产环境直接用 OZ `VestingWallet`(支持 ETH + ERC20 + cliff)

## 10. 课后练习

### 练习 1
为 TokenVesting 添加 **cliff(锁定期)**:
- 加 `uint256 public immutable cliff`(构造时传入,如 1 年)
- 在 `vestedAmount` 中加判断:`if (timestamp < start + cliff) return 0;`(cliff 前一分不给)
- 加测试:`vm.warp(block.timestamp + cliff - 1)` 时 release 应失败;`vm.warp(block.timestamp + cliff)` 时 vested = 0(刚到 cliff 仍为 0,cliff 之后才开始线性)

### 练习 2
为 TokenVesting 添加 **ETH 释放**:
- 合约 payable,`receive() external payable {}` 接收 ETH
- 加 `uint256 public ethReleased`(已发放 ETH 累计)
- `function releaseETH() public` 计算 `address(this).balance + ethReleased` 的"总 ETH 配额",按时间线性释放
- 加测试:部署时转 10 ether,`vm.warp + duration/2`,releaseETH 应转 5 ether

### 练习 3(进阶)
为 TokenVesting 实现 **多受益人 + 权重**:
- 把 `beneficiary` 改成 `address[] memory beneficiaries` + `uint256[] memory weights`
- 每个受益人按权重共享"总配额"
- 每人独立 `release(beneficiary)`,各自累计
- 加测试:Alice(权重 1)、Bob(权重 3)各 release,`vm.warp + 50%`,Alice 拿 2500,Bob 拿 7500
- 提示:这其实是 PaymentSplit + 时间维度的合体版,可以参考 OZ `VestingWallet` 的 multi-claim 模式
