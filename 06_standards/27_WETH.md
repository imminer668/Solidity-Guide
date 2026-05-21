# 第 27 课:WETH —— 把 ETH 包成 ERC20

## 1. 本节目标

学完这节课,你能:
- 说清"为什么主流 DeFi 协议(Uniswap、Aave 等)只认 WETH 不认 ETH"
- 自己手写一个最小可用的 WETH9(raw 实现)
- 用 OpenZeppelin 的 ERC20 基类快速搭一个 WETH(oz 实现)
- 理解 `deposit` / `withdraw` 与 `receive` / `fallback` 的关系
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币 (WETH 本质就是 ERC20)
- 第 14 课:Eth 与 fallback (`receive() / fallback()` 让合约能接收 ETH)
- 第 15 课:call / delegatecall (`withdraw` 用 `payable(addr).call{value:}` 退 ETH)

## 3. 先讲结论

**WETH = Wrapped Ether,把 ETH"包装"成符合 ERC20 标准的 token**。1 ETH 永远 = 1 WETH,价格 1:1 锚定。

**为什么需要包装?**
- 原生 ETH **不是 ERC20** —— 它先于 ERC20 标准存在
- 主流协议(Uniswap、AAVE、Compound)的合约接口都按 ERC20 设计,要 `transfer` / `approve` / `transferFrom`
- 原生 ETH 没有 `transferFrom`,无法被合约"代扣"
- 解决方法:把 ETH 包成 WETH(ERC20),用完再 unwrap 回 ETH

**WETH 的两个核心方法**:

| 方法 | 输入 | 效果 |
|------|------|------|
| `deposit()` | 附带 N wei ETH | 给 msg.sender 铸造 N WETH |
| `withdraw(amount)` | N WETH | 销毁 N WETH,把 N wei ETH 退回 msg.sender |

**等式**:`address(this).balance == totalSupply()` —— 合约里锁的 ETH 始终等于流通的 WETH。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/WETH.sol` + `src/raw/IERC20.sol` | ~78 行 |
| **oz** | `src/oz/WETH.sol` | ~35 行 |

## 4. 合约设计

### 4.1 关键事件

```solidity
event Deposit(address indexed dst, uint wad);     // 存 ETH 进来
event Withdrawal(address indexed src, uint wad);  // 取 ETH 出去
// 另外两个事件来自 IERC20: Transfer / Approval
```

WETH9 是 2017 年部署的合约,事件参数名 `dst` / `src` / `wad`(wad = 18 位定点数)是历史叫法,沿用至今。

### 4.2 状态结构

raw 版自己声明 ERC20 三大变量:
```solidity
mapping(address => uint256) private _balances;
mapping(address => mapping(address => uint256)) private _allowances;
// totalSupply 不存,直接 return address(this).balance
```
oz 版继承 OZ `ERC20`,直接复用 `_balances` / `_allowances` / `_totalSupply`。

### 4.3 三个 payable 入口

| 入口 | 触发条件 |
|------|---------|
| `deposit()` | 显式调用,推荐做法 |
| `receive() external payable` | 给合约直接 send ETH,带空 calldata |
| `fallback() external payable` | 调用了不存在的函数,且 msg.value > 0 |

三个入口都最终把存款逻辑跑一遍 —— 用户体验上"直接给地址转 ETH 就能换到 WETH"。

## 5. 代码拆解

### 5.1 raw 实现 —— 看清每个动作 (`src/raw/WETH.sol`)

#### deposit:接 ETH 铸 WETH
```solidity
fallback() external payable { deposit(); }
receive() external payable { deposit(); }

function deposit() public payable {
    _balances[msg.sender] += msg.value;
    emit Deposit(msg.sender, msg.value);
}
```
要点:
- `payable` 修饰才能接 ETH
- `msg.value` 是这次调用附带的 ETH 数量(单位 wei)
- 没有显式 `_totalSupply`,因为 `totalSupply()` 直接读合约 ETH 余额

#### withdraw:销 WETH 退 ETH
```solidity
function withdraw(uint amount) public {
    require(_balances[msg.sender] >= amount, "WETH: insufficient balance");
    _balances[msg.sender] -= amount;
    (bool success,) = payable(msg.sender).call{value: amount}("");
    require(success, "WETH: transfer failed");
    emit Withdrawal(msg.sender, amount);
}
```
要点:
- **先扣余额再退 ETH**(Checks-Effects-Interactions 模式,防重入)
- 用 `.call{value:}("")` 而不是 `.transfer()` —— 后者只给 2300 gas,可能让对方合约 fallback 失败
- 必须 `require(success)`,否则 ETH 退回失败不报错

#### totalSupply:用余额代替显式变量
```solidity
function totalSupply() public view returns (uint256) {
    return address(this).balance;
}
```
教学要点:这是个**省 1 个 SSTORE** 的优化。但前提是合约只通过 `deposit` 进 ETH —— 如果有 `selfdestruct` 强行打钱进来,余额会大于流通量,等式失衡。

#### transfer / approve / transferFrom
和第 24 课的 ERC20 完全一样,这里不再展开。

### 5.2 oz 实现 —— 把 ERC20 部分继承掉 (`src/oz/WETH.sol`)

```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {
    event Deposit(address indexed dst, uint wad);
    event Withdrawal(address indexed src, uint wad);

    constructor() ERC20("Wrapped Ether", "WETH") {}

    fallback() external payable { deposit(); }
    receive() external payable { deposit(); }

    function deposit() public payable {
        _mint(msg.sender, msg.value);
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(uint amount) public {
        require(balanceOf(msg.sender) >= amount, "WETH: insufficient balance");
        _burn(msg.sender, amount);
        (bool success,) = payable(msg.sender).call{value: amount}("");
        require(success, "WETH: transfer failed");
        emit Withdrawal(msg.sender, amount);
    }
}
```
要点:
- `transfer` / `approve` / `transferFrom` 都来自 OZ `ERC20`,不用写
- `deposit` 直接调 `_mint(msg.sender, msg.value)` —— OZ 提供的内部函数
- `withdraw` 调 `_burn` —— 配套对称
- OZ 的 `totalSupply()` 走 `_totalSupply` 状态变量(随 `_mint` / `_burn` 自动同步)

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| ERC20 部分 | 自己写 4 个函数 | 继承 OZ `ERC20` |
| totalSupply | 读 `address(this).balance`(隐式) | 走 `_totalSupply`(显式) |
| 代码量 | ~78 行 | ~35 行 |
| 适用 | 学原理,贴近原版 WETH9 | 生产代码 |

注:**主网上的官方 WETH9** 用的就是 raw 那种实现方式(2017 年部署,在 OZ 之前)。但今天写新代码,用 oz 更省事、更安全。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/06_standards/27_WETH
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── IERC20.sol
│   └── WETH.sol            # 原生实现(贴近 WETH9 原版)
└── oz/
    └── WETH.sol            # OZ 实现
test/
├── raw/WETH.t.sol
└── oz/WETH.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 10 个测试全部通过(raw 6 个 + oz 4 个)。

### 步骤 5:三种存款方式对比测试(`test/raw/WETH.t.sol`)

```solidity
function testDeposit() public {
    weth.deposit{value: 1 ether}();           // 方式 1:显式调用
    assertEq(weth.balanceOf(address(this)), 1 ether);
}

function testFallbackDeposit() public {
    address(weth).call{value: 0.5 ether}(""); // 方式 2:直接 send ETH(空 calldata 走 receive)
    assertEq(weth.balanceOf(address(this)), 0.5 ether);
}

function testReceiveDeposit() public {
    (bool success,) = address(weth).call{value: 0.5 ether}("");
    require(success);
    assertEq(weth.balanceOf(address(this)), 0.5 ether);
}
```
教学点:`address(weth).call{value:}("")` 中第二个参数是 `""`(空 calldata)。空 calldata + 有 ETH → 走 `receive()`;非空 calldata + 函数不存在 → 走 `fallback()`。本项目里两个 hook 都指向 `deposit()`,所以效果等价。

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 10 个测试全部 PASS:
  - **raw**: `testDeposit`、`testTotalSupply`、`testFallbackDeposit`、`testReceiveDeposit`、`testTransfer`、`testApproveAndTransferFrom`
  - **oz**: `testDeposit`、`testTotalSupply`、`testFallbackDeposit`、`testTransfer`

注:当前测试套件未覆盖 `withdraw`,留作课后练习。

## 8. 常见错误排查

### 错误 1:`withdraw` 时余额够,但 ETH 没退回来

- **常见原因**:用了 `payable(addr).transfer(amount)`,而 addr 是合约且其 fallback 消耗超过 2300 gas
- **解决步骤**:改用 `payable(addr).call{value: amount}("")`,并 `require(success)`
- **验证方式**:写个 Mock 合约,在 fallback 里写多条 SSTORE,用 `.transfer` 必失败,改 `.call` 成功

### 错误 2:`deposit` 不带 `payable`,部署后无法接收 ETH

- **常见原因**:函数没加 `payable` 修饰符
- **解决步骤**:`function deposit() public payable { ... }`
- **验证方式**:编译器对 non-payable 函数附带 msg.value 时会 revert

### 错误 3:`totalSupply()` 返回值小于流通量

- **常见原因**:raw 版用 `address(this).balance`,但其他合约用 `selfdestruct` 把 ETH 强行打进来 → balance 涨了,但流通的 WETH 没涨,导致**反过来**:totalSupply > 实际可兑换的 ETH
- **解决步骤**:生产环境建议像 oz 版那样,用显式 `_totalSupply` 字段
- **验证方式**:模拟 selfdestruct 攻击合约(0.8+ 已 deprecate,但仍可触发)

### 错误 4:把 WETH 当成 ETH 直接转给协议

- **常见原因**:Uniswap V2 的 `swap` 函数收 WETH,不是 ETH
- **解决步骤**:先 `weth.deposit{value: x}()` 换 WETH,再 `weth.approve(router, x)`,再调 `router.swap(...)`
- **验证方式**:Uniswap V2 Router 有专门的 `swapExactETHForTokens` 帮你自动 wrap,新人推荐用这个

## 9. 本节总结

- WETH 是把"原生 ETH"包成"ERC20 token"的标准合约
- `deposit` ↔ `mint`,`withdraw` ↔ `burn`,1:1 锚定 ETH
- `receive` / `fallback` 让用户**直接 send ETH 也能换到 WETH**(UX 友好)
- 用 `.call{value:}` 退 ETH,**不要**用 `.transfer`(gas 限制问题)
- 主网的官方 WETH9 是 raw 那种风格的代码,2017 年部署至今
- 写新项目用 oz 版,更安全更简洁

## 10. 课后练习

### 练习 1
为 raw 版的 `WETH.sol` **补全 `withdraw` 测试**:
- `testWithdraw`: deposit 1 ether,withdraw 0.5 ether,断言 WETH 余额 = 0.5 ether,且 `address(this).balance` 增加 0.5 ether
- `testWithdrawTooMuch`: deposit 1 ether,withdraw 2 ether,用 `vm.expectRevert` 校验
- `testWithdrawEvent`: 用 `vm.expectEmit` 校验触发了 `Withdrawal(msg.sender, amount)` 事件

### 练习 2
基于 oz 版,实现 **`depositTo(address recipient)`**:
- 把 ETH 存进来,但把 WETH 铸给 `recipient` 而不是 msg.sender
- 用途:批量空投 WETH、桥接合约代用户存款
- 加测试:Alice 调 `depositTo{value: 1 ether}(Bob)`,Bob 应有 1 WETH,Alice 没有

### 练习 3(进阶)
实现 **WETH 重入攻击防护**:
- 当前 raw 实现的 `withdraw` 走的是 Checks-Effects-Interactions(扣余额在退 ETH 之前),已是安全的
- 但模拟一个错误版本:把 `_balances[msg.sender] -= amount` 改到 `.call` 之后
- 写一个攻击合约 `Attacker`,在其 `receive` 里递归调用 `withdraw`
- 演示余额可以被多次提取,然后改回正确顺序证明攻击失效
- 推荐参考:第 20 课"重入攻击"
