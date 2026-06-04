# 第 43 课:Flashloan —— 闪电贷合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么闪电贷不需要抵押物,还能赚 0.3% 手续费"
- 自己手写一个支持 0.3% 手续费的 SimpleFlashloan(raw 实现)
- 理解"借 → 用 → 还"在同一笔交易内完成的原子性
- 理解为什么回调必须主动还款(否则整笔 revert)
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币(flashloan 操作 ERC20)
- 第 17 课:合约调用(`msg.sender.call(...)` 是调用回调的关键)
- 第 14 课:Eth 与 fallback(本课示例是 ERC20,但 ETH 也能闪电贷)

## 3. 先讲结论

**Flashloan(闪电贷) = 在同一笔交易内"借 → 用 → 还"完成贷款,无需抵押物**。如果不在同一笔交易内归还,整笔 revert。典型场景:
- **套利 arbitrage**:在 A 交易所 1 ETH 换 100 USDC,在 B 交易所 100 USDC 换 1.1 ETH,白赚 0.1 ETH
- **抵押品互换**:用闪电贷还清 A 平台借款 → 提走抵押品 → 抵押到 B 平台 → 借新钱 → 还闪电贷
- **杠杆清算**:借大笔钱清偿别人抵押品,拿走 5% 清算奖励
- **协议迁移**:从 Compound 借款还 Aave 借款,反向亦然

**为什么不需要抵押?**
- 传统贷款:借钱 → 用钱 → 还钱(可能要几周),有违约风险
- 闪电贷:借钱 → 用钱 → 还钱(**同一笔交易,无时间窗口**),违约时整笔 revert(资产归还)
- **核心**:以太坊交易的原子性 —— 要么全成功,要么全 revert,没有"借走不还"的可能

**核心流程**:
```
用户:flashloan.flashloan(token, amount, data)
   ↓
flashloan:
  1. 校验 balance 足够
  2. transfer(token, msg.sender, amount)    ← 借钱给用户
  3. msg.sender.call(abi.encodeWithSignature("onFlashloan(address,uint256,bytes)", ...))  ← 触发回调
   ↓
用户回调 onFlashloan(...):
  4. 用借来的钱做套利/清算/...
  5. transfer(token, flashloan, amount + fee)  ← 还钱 + 手续费
   ↓
flashloan:
  6. 校验 balanceAfter >= amount + fee
  7. 否则 revert,所有交易回滚
```

**手续费计算**(教学版):
```
fee = (amount * 3) / 1000 + 1   ← 0.3% + 1 wei(防精度归零)
repayAmount = amount + fee
```

**与 Aave V3 真实实现的差异**:
- Aave:多资产池、动态利率、Oracle 喂价、债务 token 化
- 本课:单一资产、固定费率、教学演示

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/Flashloan.sol`(含 SimpleFlashloan + MockERC20)+ `MockToken.sol` | 86 + 31 行 |
| **oz** | `src/oz/Flashloan.sol` | 9 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 重命名(因 raw 已用 OZ `IERC20`)。**生产环境**用 Aave V3 完整实现,或 Uniswap V2 的 `swap` 自带闪电贷功能。

## 4. 合约设计

### 4.1 状态

```solidity
contract SimpleFlashloan {
    uint256 public constant FEE = 3; // 0.3% fee (like Uniswap V2)
    
    function flashloan(address token, uint256 amount, bytes calldata data) external { ... }
}
```

`FEE` 是 `constant` 常量 3,除以 1000 等于 0.003 = 0.3%。

### 4.2 关键约束:回调函数签名

```solidity
bytes memory data = abi.encodeWithSignature(
    "onFlashloan(address,uint256,bytes)",
    address(this),
    amount,
    data
);
```

教学点:
- 借贷方主动调 `msg.sender.call(...)` 触发回调
- 回调函数签名 **必须** 是 `onFlashloan(address,uint256,bytes)`,否则 revert
- `data` 是用户传给 flashloan 的原始 bytes,被原样转发(用户可用它传"套利参数"等)

### 4.3 手续费"加 1 wei"技巧

```solidity
uint256 fee = (amount * FEE) / 1000 + 1;   // ← +1 防整除归零
```

教学点:**0.3% 手续费在 amount 极小时会归零**(如 amount=1, fee=0,攻击者可借 1 wei 免费用)。加 1 wei 保证 fee > 0。

### 4.4 业务流程

```
部署 flashloan 合约
   ↓
项目方:token.mint(flashloan, 1000e18)   ← 注入流动性
   ↓
用户部署 receiver 合约,实现 onFlashloan 回调
   ↓
用户调 receiver.requestFlashloan(amount)
   ↓
receiver 调 flashloan.flashloan(token, amount, "")
   ↓
flashloan:
  1. 校验 amount > 0, balance 足够
  2. transfer(token, receiver, amount)  ← 借钱
  3. receiver.onFlashloan(...)
       ↓
     receiver 在回调内:
       - 用借来的钱做套利(买低卖高)
       - transfer(token, flashloan, amount + fee)  ← 还钱
   ↓
  4. 校验 balanceAfter >= amount + fee
```

## 5. 代码拆解

### 5.1 raw 实现 —— SimpleFlashloan (`src/raw/Flashloan.sol`)

```solidity
function flashloan(address token, uint256 amount, bytes calldata data) external {
    require(amount > 0, "Amount must be positive");
    
    uint256 balanceBefore = IERC20(token).balanceOf(address(this));
    require(balanceBefore >= amount, "Insufficient balance");
    
    // 1. 借钱给调用者
    IERC20(token).transfer(msg.sender, amount);
    
    // 2. 触发回调(用户必须在此回调内还款)
    (bool success, ) = msg.sender.call(
        abi.encodeWithSignature("onFlashloan(address,uint256,bytes)", address(this), amount, data)
    );
    require(success, "Flashloan callback failed");
    
    // 3. 校验还款
    uint256 fee = (amount * FEE) / 1000 + 1;
    uint256 repayAmount = amount + fee;
    uint256 balanceAfter = IERC20(token).balanceOf(address(this));
    require(balanceAfter >= repayAmount, "Repayment failed");
}
```

要点:
- **先借钱后回调**:用户借到手,才能去做套利
- **回调失败 revert**:回调里"业务逻辑"如果失败(套利无利可图、清算失败等),整笔 revert,资金归还
- **回调成功后校验还款**:`balanceAfter >= repayAmount` 检查是否还够
- **没有显式还款**:用户**自己**在回调内调 `transfer(flashloan, repayAmount)`,借方不主动扣

### 5.2 接收方合约:FlashloanReceiver

```solidity
function onFlashloan(address, uint256 amount, bytes calldata) external returns (bool) {
    require(msg.sender == address(flashloan), "Only flashloan");
    
    uint256 fee = (amount * 3) / 1000 + 1;
    uint256 repayAmount = amount + fee;
    
    // 关键:在回调内还款
    MockERC20(token).transfer(address(flashloan), repayAmount);
    
    return true;
}
```

教学点:
- **`require(msg.sender == address(flashloan))`** 防伪调用(任何人都可以调 onFlashloan,但只有 flashloan 调才有效)
- **必须在回调内还款**:回调结束 flashloan 会检查余额,不够就 revert
- 真实套利场景:在 onFlashloan 内调 DEX 套利 + 还款

### 5.3 MockERC20(教学用)

```solidity
contract MockERC20 {
    string public name;
    string public symbol;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    function mint(address to, uint256 amount) external { ... }  // 测试用 mint
    function transfer / approve / transferFrom ...              // 标准 ERC20
}
```

要点:
- 教学用的极简 ERC20,带 mint 暴露(生产 ERC20 不会这样)
- 仅供本课测试,生产用 OZ `ERC20`

### 5.4 oz 实现 —— `src/oz/Flashloan.sol`

```solidity
import {SimpleFlashloan} from "../../src/raw/Flashloan.sol";

contract SimpleFlashloanOZ is SimpleFlashloan {}
```

要点:
- 业务完全一致
- 本项目 oz 版只是命名占位

### 5.5 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| IERC20 | 用 OZ 的 | 继承 raw |
| 代码量 | ~35 行(flashloan 部分) | ~9 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 Aave V3 完整实现**:复杂得多,带债务 token、利率策略、Oracle 喂价、多资产池等。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/09_protocols/43_Flashloan
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── MockToken.sol           # 测试用 OZ ERC20
│   └── Flashloan.sol           # 原生 SimpleFlashloan + 内嵌 MockERC20
└── oz/
    └── Flashloan.sol           # OZ 版(继承 raw)
test/
├── raw/Flashloan.t.sol         # 含 FlashloanReceiver + 4 个测试
└── oz/Flashloan.t.sol          # 1 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 5 个测试全部通过(raw 4 个 + oz 1 个)。

### 步骤 5:重点测试 —— 完整借-还流程(`test/raw/Flashloan.t.sol`)

```solidity
function testFlashloanWithRepayment() public {
    uint256 borrowAmount = 100e18;
    uint256 initialFlashloanBalance = token.balanceOf(address(flashloan));
    
    // 给 receiver 转入足额还款(模拟"用户已有钱还款"或"套利赚到钱")
    uint256 fee = (borrowAmount * 3) / 1000 + 1;
    token.mint(address(receiver), fee + 10e18);
    
    vm.prank(address(receiver));
    receiver.requestFlashloan(borrowAmount);  // 触发完整流程
    
    // 验证 flashloan 合约的余额增加(手续费留下)
    assertGt(token.balanceOf(address(flashloan)), initialFlashloanBalance);
}
```

教学点:
- `vm.prank(receiver)` 切换 msg.sender 为 receiver(因为 requestFlashloan 调 flashloan.flashloan 时 flashloan 内部用 msg.sender 调回调)
- 测试中**给 receiver 充 fee + 10 wei**,模拟"receiver 用套利收益还款"或"receiver 本来就有钱"
- `assertGt(balance, initialBalance)` flashloan 合约余额涨了(因为多了手续费)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 5 个测试全部 PASS:
  - **raw**: `testInitialState`、`testFlashloanWithRepayment`、`testRevertInsufficientBalance`、`testRevertZeroAmount`
  - **oz**: `testInitialState`

## 8. 常见错误排查

### 错误 1:`flashloan` 报 "Flashloan callback failed"

- **常见原因**:接收方 onFlashloan 回调 revert
- **解决步骤**:在 onFlashloan 内部加 try-catch / console.log 调试
- **验证方式**:用 `vm.expectRevert` 校验子调用

### 错误 2:`flashloan` 报 "Repayment failed"

- **常见原因**:回调内还款金额不足(amount + fee)
- **解决步骤**:在 onFlashloan 内算准 repayAmount,确保 balance 够
- **验证方式**:`testFlashloanWithRepayment` 显式 `token.mint(receiver, fee + 10e18)`

### 错误 3:套利无利可图,回调 revert

- **常见原因**:套利交易预期利润为负(slippage / gas / 价格变化)
- **解决步骤**:
  - 套利前先模拟:用 `getAmountsOut` 预估
  - 留足利润空间
  - 用 `simulate` 函数预演(不真上链)
- **验证方式**:用 Foundry `vm.expectRevert` 模拟"无利可图"的场景

### 错误 4:回调时 receiver 没足够 token 还款

- **常见原因**:receiver 余额不足(没 mint,或套利没赚到)
- **解决步骤**:
  - 测试中用 `token.mint(receiver, ...)` 充钱
  - 生产中确保套利利润 >= 手续费
- **验证方式**:`testFlashloanWithRepayment` 中 `token.mint(receiver, fee + 10e18)`

## 8.5 本课安全边界

> 集中安全知识见第 20 课(常见漏洞与防护),本节只列**与 Flashloan / 借出方合约直接相关**的坑点。

### 坑 1:回调时重入借方合约(重入攻击)

**现象**:借方合约的 `onFlashloan` 没防重入,被回调里再调 `flashloan.flashloan(...)` → **同一笔交易内递归借出**,复利放大余额。

**修复**:
- 借方合约:加 `ReentrancyGuard`,或在 `onFlashloan` 开头 `require(!locked)`
- 借出方:在 `flashloan` 里也加锁(防止攻击者通过借出方回调借出方)

```solidity
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract SimpleFlashloan is ReentrancyGuard {
    function flashloan(...) external nonReentrant { ... }
}
```

### 坑 2:回调时价格预言机被操纵

**现象**:在 onFlashloan 里调 DEX 看现货价做套利,但攻击者:
1. front-run 你的 flashloan 交易 → 推高/砸盘价格
2. 你的回调内看到"价差"开仓
3. back-run 把价格砸回 → 你爆仓

**修复**:
- **不要在 flashloan 回调内用现货价**
- 用 **TWAP**(时间加权平均价,Uniswap V2 `priceCumulativeLast`)
- 套利利润空间留足,覆盖预测误差

### 坑 3:接收方合约 callback 失败时整笔 revert,gas 损失

**现象**:借方 onFlashloan 里"业务逻辑"失败(套利无利可图、清算失败等),**整笔 flashloan 交易 revert**:
- 借方白付出 gas(已部署的 receiver 合约、state 写入)
- 借出方:有"gas 退还"机制的话省一些(Aave V3 有)

**修复**:
- 套利前用 simulate / `staticcall` 预估利润(不进 transferFrom / transfer)
- 借出方角度:`try-catch` 接收方回调,失败时至少记日志

### 坑 4:非白名单接收方 = 任意合约都能借

**现象**:SimpleFlashloan 没限制 receiver,任何合约都能 `flashloan(token, amount, "")`,可能被用作洗钱 / 攻击工具。

**修复**:
```solidity
mapping(address => bool) public whitelisted;

function flashloan(...) external {
    require(whitelisted[msg.sender], "Not whitelisted");
    // ...
}
```

**或**用 hook 形式:接收方必须实现 `IFlashBorrower`,且是已知合约。

### 坑 5:USDT 不返回 bool,balanceAfter 校验出错

**现象**:SimpleFlashloan 用 `balanceAfter >= repayAmount` 校验还款,但 **如果 `amount + fee` 是普通数字**,USDT 转账时虽然"扣了 amount",但若 balanceAfter 是用 `balanceOf` 查 USDT 实际合约,可能**先看到 transfer out 后的余额**(已扣 amount,未加 fee)→ 误判失败。

**修复**:
- **校验时再用 `balanceOf(this)` 实时查**(转账是 sync 的,会更新)
- 用 `SafeERC20.safeTransferFrom` 走标准库,失败 revert

```solidity
uint256 balanceAfter = IERC20(token).balanceOf(address(this));
require(balanceAfter >= balanceBefore + fee, "Repayment failed");
```

### 坑 6:0.3% 手续费极小金额归零

**现象**:`fee = amount * 3 / 1000`。借 `amount = 1` → `fee = 0`,攻击者借 1 wei 免费用,repay 后**金额不变**(fee = 0)。

**修复**:+1 wei 保底:
```solidity
uint256 fee = (amount * FEE) / 1000 + 1;  // 本课已做
```

### 坑 7:回调里 transferFrom 自己 = 自还款攻击

**现象**:接收方 onFlashloan 内**先**调 `token.transferFrom(flashloan, flashloan, amount)`(从自己借的 token 又 transferFrom 回自己),**后**再调 `token.transfer(flashloan, repayAmount)`。这导致 balanceAfter 校验时,flashloan 余额正确,但**实际并未消耗借来的 token**(因为 transferFrom 把 token 转到 flashloan,但没扣 receiver 的钱)。

实际不会出问题(因为 `transferFrom(from, to, amount)` 永远是 from → to,不能从自己 to 自己走 transferFrom)。但**接收方构造不当**可能导致:
- 借出 token **被锁在 receiver 合约**(没归还)
- 还款额 **来自第三方**(洗钱)

**修复**:借出方在 `balanceAfter` 校验时,确保**余额真的增加了**(`balanceAfter >= balanceBefore + fee`)。

### 关键防御清单

| 风险 | 防御 |
|------|------|
| 回调重入 | 借出方 + 借方都加 `ReentrancyGuard` |
| 预言机操纵 | 不用现货价,改用 TWAP |
| 回调失败 | `try-catch` + `staticcall` 预演 |
| 任意 receiver | 白名单 / 必须实现 IFlashBorrower |
| USDT 不返回 bool | `SafeERC20`,实时 `balanceOf` 校验 |
| 极小额 fee 归零 | `+1 wei` 保底 |
| 自还款构造 | 校验 `balanceAfter - balanceBefore == fee` |

> Flashloan 本身是工具,真正赚钱的是"如何在回调里构造无风险套利",这部分内容第 43 课延伸阅读会讲。

## 9. 本节总结

- 闪电贷 = **借 → 用 → 还** 在同一笔交易内完成,无需抵押
- 核心:`msg.sender.call(...)` 触发接收方回调,接收方在回调内还款
- 校验还款:`balanceAfter >= amount + fee`,不足 revert
- 手续费 0.3% + 1 wei(防精度归零)
- 实战:套利 arbitrage、抵押品互换、杠杆清算、协议迁移
- 教学版 SimpleFlashloan 与 Aave V3 真实实现的差异:多资产池、动态利率、Oracle 喂价
- 与本单元其他课对比:本课是"高级应用",依赖前面所有基础
- 配合 DEX(42 课)做套利、配合 NFTSwap(40 课)做抵押品互换
- 配合 ERC20Permit(37 课)做"一笔交易完成"无授权套利
- 写 flashloan 最常踩的坑:回调重入、预言机操纵、白名单、USDT 校验、fee 归零

## 10. 课后练习

### 练习 1
为 SimpleFlashloan 加 **"完整套利示例"**:
- 部署 2 个 DEX(本课 SimpleSwap ×2),价格有差异
- 写一个套利 receiver:借 token0 → 在 A 卖 → 在 B 买 token0 → 还款 + 利润
- 加测试:人为让 A/B 价格有差异,跑套利 receiver,验证 receiver 赚到差额

### 练习 2
为 SimpleFlashloan 加 **"白名单借款人"**:
- 加 `mapping(address => bool) public whitelisted;`
- flashloan 校验 `whitelisted[msg.sender] == true`
- 加测试:非白名单调用 revert,白名单可借

### 练习 3(进阶)
基于 raw 的 SimpleFlashloan,实现 **"批量借多种 token"**:
- 暴露 `function flashloanBatch(FlashloanRequest[] calldata reqs) external`
- 一次性借多种 token,统一回调,统一还款
- 加测试:借 token0 + token1,回调内分别还 + 手续费,验证 flashloan 余额都增加
- 提示:这是 Aave V3 的"多资产池"教学版
