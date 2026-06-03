# 第 42 课:DEX —— 简单自动做市商(AMM)

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 Uniswap 用 x*y=k 公式,而不是订单簿(order book)"
- 自己手写一个 Uniswap V2 风格的 SimpleSwap(raw 实现)
- 理解 `getAmountOut` 公式的物理意义
- 理解"首次 LP = sqrt(x*y)"和"后续 LP 按比例"的会计
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币(AMM 交易 ERC20)
- 第 11 课:Keccak256 / 整数运算(价格公式核心是除法)
- 第 17 课:合约调用(`token.transferFrom` 是 LP 入金 + swap 的关键)

## 3. 先讲结论

**DEX(去中心化交易所) = 让用户用代币换代币,无需中心化撮合**。SimpleSwap 是 **Uniswap V2 风格的 AMM(自动做市商)**,核心思想:
- **传统交易所**:挂单簿,买一卖一,中心化撮合
- **AMM**:**x * y = k 恒定乘积公式**,价格自动算出,任何人都能当 LP(流动性提供者)

典型应用:
- **Uniswap V2/V3**:DeFi 最大的 DEX
- **SushiSwap**:Uniswap fork
- **PancakeSwap**:BSC 上的 DEX
- **Curve**(stableswap 变种)

**AMM vs 订单簿**:

| 维度 | 订单簿(中心化) | AMM(链上) |
|------|----------------|-----------|
| 流动性来源 | 做市商挂单 | LP 存代币 |
| 价格发现 | 撮合引擎 | x*y=k 公式 |
| 交易速度 | 毫秒 | 区块确认(12s) |
| 链上 gas | 低(链下) | 高(链上) |
| 抗审查 | 弱 | 强 |
| 大单滑点 | 低(深挂单) | 高(公式固定) |

**核心公式**:

```
addLiquidity(首存):liquidity = sqrt(amount0 * amount1)
addLiquidity(后续):liquidity = min(amount0/reserve0, amount1/reserve1) * totalSupply
removeLiquidity:    amountOut = (liquidity / totalSupply) * reserve
getAmountOut:       amountOut = amountIn * reserveOut / (reserveIn + amountIn)
```

**x*y=k 推导**:
```
交换前:reserveIn * reserveOut = k
交换后:(reserveIn + amountIn) * (reserveOut - amountOut) = k
解 amountOut = amountIn * reserveOut / (reserveIn + amountIn)
```

举栗:reserveIn=100, reserveOut=100, amountIn=10
- amountOut = 10 * 100 / (100 + 10) = 9.09
- 滑点:(9.09 / 10) - 1 = -9.1%(预期 0 滑点,实际 9.1% 滑点)

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/SimpleSwap.sol` | ~156 行 |
| **oz** | `src/oz/SimpleSwap.sol` | ~10 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 重命名(因 raw 已用 OZ `ERC20`)。**生产环境**用 Uniswap V2 / V3 完整实现(数千行,带手续费、Router、Factory、闪电贷等)。本课是教学版,**无 0.3% 手续费**。

## 4. 合约设计

### 4.1 状态

```solidity
IERC20 public token0;     // 交易对 token A
IERC20 public token1;     // 交易对 token B
uint public reserve0;     // 金库里 token0 的余额(简化版用 state 变量)
uint public reserve1;     // 金库里 token1 的余额
```

**`SimpleSwap 本身是 ERC20`**(继承 OZ):LP token 是 ERC20,可转账、可组合。

### 4.2 三个核心方法

| 方法 | 作用 |
|------|------|
| `addLiquidity(amount0, amount1) → liquidity` | LP 存两种 token,获得 LP token |
| `removeLiquidity(liquidity) → (amount0, amount1)` | LP 销毁 LP token,取回两种 token |
| `swap(amountIn, tokenIn, amountOutMin) → (amountOut, tokenOut)` | 用户用 tokenIn 换 tokenOut |

### 4.3 业务流程

```
用户:token0.approve(swap, 100e18)
     token1.approve(swap, 100e18)
用户:swap.addLiquidity(100e18, 100e18)
     → liquidity = sqrt(100e18 * 100e18) = 100e18
     → LP 持有 100e18 SimpleSwap(LP token)
     → 金库储备 100e18 token0 + 100e18 token1
     ↓
用户 B:token0.approve(swap, 10e18)
用户 B:swap.swap(10e18, token0, 0)
     → amountOut = 10e18 * 100e18 / (100e18 + 10e18) ≈ 9.09e18
     → token0 入金库,token1 出金库
     → 储备 110e18 token0 + 90.91e18 token1 (x*y = 110*90.91 ≈ 10000 = k)
     ↓
LP:swap.removeLiquidity(100e18)
     → amount0 = 100e18 * 110e18 / 200e18 = 55e18
     → amount1 = 100e18 * 90.91e18 / 200e18 ≈ 45.45e18
```

### 4.4 关键设计选择

- **reserve 显式存**:每次 add/remove/swap 后 `reserve0 = balanceOf(this)`(简单同步,实际生产用更优方式)
- **首存 `sqrt(x*y)`**:让 LP 比例与"提供流动性比例"成正比
- **后续按 `min(ratio0, ratio1)`**:确保两个 token 按当前价格比例添加(防单边加)
- **滑点保护**:`amountOutMin`,swap 出量 < 最小值就 revert

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/SimpleSwap.sol`

#### sqrt:巴比伦法求平方根
```solidity
function sqrt(uint y) internal pure returns (uint z) {
    if (y > 3) {
        z = y;
        uint x = y / 2 + 1;
        while (x < z) {
            z = x;
            x = (y / x + x) / 2;
        }
    } else if (y != 0) {
        z = 1;
    }
}
```

要点:
- 牛顿迭代法求 `sqrt(y)`,数学上 `x_{n+1} = (y/x_n + x_n) / 2`
- 不用 Solidity 0.8 内置 `Math.sqrt` 是为了兼容老版本
- 实际生产用 OZ `Math.sqrt` 即可

#### addLiquidity:首存 + 后续
```solidity
function addLiquidity(uint amount0Desired, uint amount1Desired) public returns(uint liquidity) {
    token0.transferFrom(msg.sender, address(this), amount0Desired);
    token1.transferFrom(msg.sender, address(this), amount1Desired);
    
    uint _totalSupply = totalSupply();
    if (_totalSupply == 0) {
        liquidity = sqrt(amount0Desired * amount1Desired);  // 首次:sqrt
    } else {
        liquidity = min(
            amount0Desired * _totalSupply / reserve0,
            amount1Desired * _totalSupply / reserve1
        );                                                   // 后续:min 比例
    }
    
    require(liquidity > 0, 'INSUFFICIENT_LIQUIDITY_MINTED');
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));
    _mint(msg.sender, liquidity);
    emit Mint(msg.sender, amount0Desired, amount1Desired);
}
```

要点:
- **先收 token,后铸 LP**(CEI 变体)
- `min(ratio0, ratio1)` 保证两个 token 按当前价格比例添加(多余的部分"算白送",实际生产应有 `amount0Min / amount1Min` 保护)
- LP = sqrt(x*y) 推导:让 LP token 价值与 pool 份额成线性关系

#### getAmountOut:x*y=k 推导
```solidity
function getAmountOut(uint amountIn, uint reserveIn, uint reserveOut) public pure returns (uint amountOut) {
    require(amountIn > 0, 'INSUFFICIENT_AMOUNT');
    require(reserveIn > 0 && reserveOut > 0, 'INSUFFICIENT_LIQUIDITY');
    amountOut = amountIn * reserveOut / (reserveIn + amountIn);
}
```

要点:
- 公式:`(reserveIn + amountIn) * (reserveOut - amountOut) = reserveIn * reserveOut`
- 解:`amountOut = amountIn * reserveOut / (reserveIn + amountIn)`
- **教学点:无手续费**(本课),Uniswap V2 实际扣 0.3%:
  - `amountInWithFee = amountIn * 997`
  - `amountOut = amountInWithFee * reserveOut / (reserveIn * 1000 + amountInWithFee)`

#### swap:执行交易
```solidity
function swap(uint amountIn, IERC20 tokenIn, uint amountOutMin) external returns (uint amountOut, IERC20 tokenOut) {
    require(amountIn > 0, 'INSUFFICIENT_OUTPUT_AMOUNT');
    require(tokenIn == token0 || tokenIn == token1, 'INVALID_TOKEN');
    
    uint balance0 = token0.balanceOf(address(this));
    uint balance1 = token1.balanceOf(address(this));
    
    if (tokenIn == token0) {
        tokenOut = token1;
        amountOut = getAmountOut(amountIn, balance0, balance1);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    } else {
        tokenOut = token0;
        amountOut = getAmountOut(amountIn, balance1, balance0);
        require(amountOut > amountOutMin, 'INSUFFICIENT_OUTPUT_AMOUNT');
        tokenIn.transferFrom(msg.sender, address(this), amountIn);
        tokenOut.transfer(msg.sender, amountOut);
    }
    
    reserve0 = token0.balanceOf(address(this));
    reserve1 = token1.balanceOf(address(this));
    emit Swap(msg.sender, amountIn, address(tokenIn), amountOut, address(tokenOut));
}
```

要点:
- `amountOutMin` 滑点保护(防三明治攻击)
- 读 balance **在 transferFrom 之前**(因 transferFrom 后 balance 变化)
- `require(tokenIn == token0 || tokenIn == token1)` 防传入非法 token

### 5.2 oz 实现 —— `src/oz/SimpleSwap.sol`

```solidity
contract SimpleSwapOZ is SimpleSwapRaw {
    constructor(IERC20 _token0, IERC20 _token1) SimpleSwapRaw(_token0, _token1) {}
}
```

要点:
- 业务完全一致
- 本项目 oz 版只是命名占位

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| ERC20 | 用 OZ 的 | 继承 raw |
| 代码量 | ~156 行 | ~10 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 Uniswap V2 完整实现**:带 0.3% 手续费 + Router + Factory + 价格预言机(TWAP)。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/09_protocols/42_DEX
```

### 步骤 2:查看文件结构

```
src/
├── raw/SimpleSwap.sol       # 原生 SimpleSwap(~156 行,Uniswap V2 教学版)
└── oz/SimpleSwap.sol        # OZ 版(继承 raw)
test/
├── raw/SimpleSwap.t.sol     # 6 个测试
└── oz/SimpleSwap.t.sol      # 2 个测试
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

### 步骤 5:重点测试 —— swap 公式验证(`test/raw/SimpleSwap.t.sol`)

```solidity
function testSwap() public {
    swap.addLiquidity(100e18, 100e18);  // 1:1 储备
    
    uint256 amountIn = 10e18;
    uint256 expectedOut = swap.getAmountOut(amountIn, 100e18, 100e18);  // 9.09e18
    
    (uint256 amountOut, IERC20 tokenOut) = swap.swap(amountIn, IERC20(address(token0)), 0);
    
    assertEq(address(tokenOut), address(token1));
    assertEq(amountOut, expectedOut);
    assertEq(amountOut, 9090909090909090909);  // 约 9.09e18
}
```

教学点:
- 100 token0 换 100 token1 储备,送 10 token0 → 拿 ~9.09 token1
- 9.09% 滑点:因为"价格曲线"在 (100,100) 附近,小单滑点小,大单滑点大
- `amountOutMin = 0` 实际生产应给滑点保护(如 `expectedOut * 95 / 100`)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS:
  - **raw**: `testInitialState`、`testAddLiquidity`、`testAddLiquidityMultipleLPs`、`testSwap`、`testRemoveLiquidity`、`testGetAmountOut`
  - **oz**: `testInitialState`、`testAddLiquidity`

## 8. 常见错误排查

### 错误 1:`addLiquidity` 报 "INSUFFICIENT_LIQUIDITY_MINTED"

- **常见原因**:后续加 LP 时,加的两个 token 比例与 reserve 严重失衡
- **解决步骤**:按当前 reserve 比例加 LP,或者用 Router 自动配比
- **验证方式**:`testAddLiquidity` 中加 100/100 平衡对

### 错误 2:`swap` 报 "INSUFFICIENT_OUTPUT_AMOUNT"

- **常见原因**:`amountOut < amountOutMin`(滑点保护触发)
- **解决步骤**:把 `amountOutMin` 设小点,或先用 `getAmountOut` 预估
- **验证方式**:`testSwap` 用 `amountOutMin = 0`(测试用,生产慎用)

### 错误 3:`getAmountOut` 整数除法精度损失

- **常见原因**:`amountIn * reserveOut / (reserveIn + amountIn)` 大数除法丢精度
- **解决步骤**:用 OZ `Math.mulDiv`(支持 fullMath 模式)
- **验证方式**:`amountIn=10, reserveIn=100, reserveOut=100` → 10*100/110 = 9.09(实际 9.09090909...,整数除法丢)

### 错误 4:三明治攻击(sandwich attack)

- **常见原因**:大单 swap 滑点大,夹子机器人(front-run + back-run)赚差价
- **解决步骤**:
  - 给 `amountOutMin` 留余量(95-99% of expected)
  - 拆单(用 TWAP / 限价单)
  - 私池(避免公共 mempool 监控)
- **验证方式**:模拟 front-run,看你的 swap 拿到的 amountOut 是否会变少

## 8.5 本课安全边界

> 集中安全知识见第 20 课(常见漏洞与防护),本节只列**与 AMM / DEX 直接相关**的坑点。

### 坑 1:三明治攻击(sandwich)

**现象**:用户要 swap 100 token0 → token1(预期拿 9.09 token1,滑点 9%)。攻击者:
1. **Front-run**:在用户交易前 swap 1 → 推高 token0 价
2. 用户交易上链,实际只拿到 5 token1(滑点 50%)
3. **Back-run**:攻击者 swap 回,赚用户亏的 4 token1

**修复**:
```solidity
// 用户角度:给 amountOutMin 留余量(预期 90%)
uint256 expectedOut = getAmountOut(amountIn, reserve0, reserve1);
uint256 amountOutMin = expectedOut * 90 / 100;  // 接受 10% 滑点
swap(amountIn, tokenIn, amountOutMin);

// 协议角度:大额拆单(分多次 swap) / 用 TWAP 限价
```

### 坑 2:储备金用 state 变量 = 捐赠攻击

**现象**:SimpleSwap 教学版把 `reserve0` / `reserve1` 存到 state,但 swap 时用 `balanceOf` 同步。攻击者:
1. 在 swap 前 `transfer(token0, pair, 1000)` 直接捐赠
2. reserve0 没变(还没 sync),但 balanceOf 变了
3. 攻击者用 1 wei 就能 swap 走 pair 里所有 token1(因为公式用 balance0)

**修复**:
- **不要用 state 存 reserve**,只读 `balanceOf`
- 每次 swap **前后**校验:`balance0 * balance1 >= reserve0 * reserve1`(K 不变量)
- 教学版用 state 变量是简化,**生产 Uniswap V2 核心是 TWAP + 重入锁 + K 不变量**

```solidity
// 生产风格:不要 reserve,只读 balance
function swap(...) external {
    uint256 balance0 = token0.balanceOf(address(this));
    uint256 balance1 = token1.balanceOf(address(this));
    
    // ... swap 后 ...
    
    // K 不变量检查
    require(balance0Adjusted * balance1Adjusted >= balance0 * balance1, "K");
}
```

### 坑 3:整数除法精度损失

**现象**:`amountIn * reserveOut / (reserveIn + amountIn)` 三个 uint256 相乘可能溢出,且除法在中间会丢精度。

**修复**:
```solidity
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
amountOut = Math.mulDiv(amountIn, reserveOut, reserveIn + amountIn);
```

`mulDiv` 用 512-bit 中间值避免溢出和精度损失(Uniswap V2 用的也是这个)。

### 坑 4:单边加池被三明治

**现象**:用户调 `addLiquidity(100 token0, 0 token1)` 单边加池(代码不拦),实际应当 revert 或者按价格自动配 amount1。

**修复**:
```solidity
require(amount0Desired > 0 && amount1Desired > 0, "INSUFFICIENT_LIQUIDITY");

// 后续 LP 按当前 reserve 比例
uint256 amount0Optimal = amount1Desired * reserve0 / reserve1;
uint256 amount1Optimal = amount0Desired * reserve1 / reserve0;
require(amount0Optimal <= amount0Desired, ...);
require(amount1Optimal <= amount1Desired, ...);
```

### 坑 5:removeLiquidity 无 amountMin

**现象**:用户 LP 提款时没设最小 amount 保护,被三明治同样攻击(份额被操纵到极小值时,提款人拿不到东西)。

**修复**:
```solidity
function removeLiquidity(
    uint256 liquidity,
    uint256 amount0Min,
    uint256 amount1Min
) external returns (uint256 amount0, uint256 amount1);
```

### 坑 6:流动性首发者"毒 LP"攻击

**现象**:第一个 LP 在 `totalSupply == 0` 时,`liquidity = sqrt(x*y)`。如果只存 1 wei token0 + 1e18 token1,后续 LP 都被比例卡住。

**修复**:
- 协议角度:首存时要求最小流动性
- Uniswap V2:首存时把 1000 LP 永久锁给 `address(0)`,防首存人独占池

### 坑 7:重入(addLiquidity 内 transferFrom 回调)

**现象**:用户是合约,`token0` 又是 ERC777(有 tokensToSend 回调),在 `transferFrom(msg.sender, pair, ...)` 时回调用户合约 → 用户重入 addLiquidity 拿双倍 LP。

**修复**:
- 教学代码不重入 → 生产加 `ReentrancyGuard`(锁)
- 顺序遵循 CEI:先转出,再写状态,再 emit

### 关键防御清单

| 风险 | 防御 |
|------|------|
| 三明治攻击 | `amountOutMin` 留余量,大单拆单 |
| 捐赠攻击 | 用 `balanceOf`,加 K 不变量检查 |
| 整数精度 | OZ `Math.mulDiv` |
| 单边加池 | 要求 amount0 + amount1 都 > 0,或按比例强制配比 |
| remove 无 amountMin | 暴露 `amount0Min` / `amount1Min` |
| 重入(ERC777) | `ReentrancyGuard`,CEI 顺序 |
| 价格预言机操纵 | 用 TWAP,不在回调内查现货 |

> AMM 的核心安全模型在第 20 课(DeFi 攻击面)再系统讲;本节先把 DEX 自己最相关的坑列出来。

## 9. 本节总结

- AMM = **x*y=k 恒定乘积公式**做市的 DEX
- SimpleSwap 是 Uniswap V2 教学版,**无 0.3% 手续费**
- 三个核心方法:addLiquidity / removeLiquidity / swap
- 首存 LP = sqrt(x*y);后续 LP = min 比例
- `getAmountOut` = `amountIn * reserveOut / (reserveIn + amountIn)`,推导自 x*y=k
- 滑点保护:`amountOutMin`,防三明治攻击
- LP token 本身是 ERC20,可转账可组合
- 实战:Uniswap V2/V3、SushiSwap、PancakeSwap、Curve
- 与本单元其他课对比:本课是"基础设施"课,DeFi 生态的核心
- 配合 NFTSwap(40 课)可做 NFT 池;配合 PaymentSplit(30 课)可分 LP 收益
- 写 DEX 最常踩的坑:三明治、捐赠攻击、精度损失、单边加池、重入

## 10. 课后练习

### 练习 1
为 SimpleSwap 加 **0.3% 手续费**:
- `getAmountOut` 改为 `amountInWithFee * reserveOut / (reserveIn * 1000 + amountInWithFee)`,其中 `amountInWithFee = amountIn * 997`
- 加 `uint256 public feeAccumulated0;` `uint256 public feeAccumulated1;` 记录累积手续费
- 加测试:swap 后 `feeAccumulated0 += 0.3% * amountIn`

### 练习 2
为 SimpleSwap 加 **价格预言机 TWAP**:
- 加 `mapping(uint256 => uint256) public priceCumulativeLast;` 记录累计价格
- 在 swap 时更新:`priceCumulativeLast[block.number] += reserve1 * 1e18 / reserve0`
- 加测试:连续 swap 后,价格累计值能正确反映时间段内价格变化

### 练习 3(进阶)
基于 raw 的 SimpleSwap,实现 **"单边存款"模式**:
- 加 `function addLiquiditySingleSide(uint amount0, uint amount1MinOut) external`
- 用户只存一种 token(如 token0),系统用一半存 reserve,另一半 swap 成 token1 加入池
- 加测试:存 100 token0,验证最终 reserve0 + reserve1 同步增加,LP 拿到合理份额
- 提示:这是 Balancer 类的"灵活 LP"模式
