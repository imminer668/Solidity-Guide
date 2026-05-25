# 第 30 课:PaymentSplit —— 按股份分账合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么要把'按比例分钱'独立成合约,不是直接 transfer N 笔"
- 自己手写一个最小可用的分账合约(raw 实现)
- 理解 `pendingPayment` 公式如何在"持续收款"下正确计算每人当前可领
- 理解 `released` / `totalReleased` 两个累计变量的意义
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 14 课:Eth 与 fallback (`receive()` 接 ETH;`payable(addr).call{value:}` 退 ETH)
- 第 8 课:数组、结构体与映射 (`address[] payees` 配 `mapping shares` 是分账标配)
- 第 13 课:Event 与日志 (`PaymentReceived` / `PaymentReleased` 用于审计)

## 3. 先讲结论

**PaymentSplit = 按预设份额(`shares`)把合约收到的 ETH 按比例分给多个受益人**。典型场景:
- DAO 治理金库:5 个核心成员各占 1 份,Treasury 30 份
- NFT 项目:艺术家 40%、平台 10%、社区国库 50%
- 团队分润:CEO 4 份 / CTO 3 份 / 工程师各 1 份

**为什么独立成合约**:
- 把"按比例分配"逻辑固化在链上,**所有人都能验证**
- 收款方**自助 pull**,项目方不用每次手动 transfer
- 中途可以继续收款,**累计公式自动按比例分配新增金额**

**核心公式**:

```
pendingPayment(user) = (totalReceived * shares[user]) / totalShares - released[user]
```

其中 `totalReceived = address(this).balance + totalReleased` —— 已收 = 当前余额 + 已发出。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/PaymentSplit.sol` | ~68 行 |
| **oz** | `src/oz/PaymentSplit.sol` | ~67 行 |

> 注:本项目两版的源码几乎完全一致 —— 都是参考 OZ `PaymentSplitter` 的精简版。生产环境推荐直接用 OZ `@openzeppelin/contracts/finance/PaymentSplitter.sol`。

## 4. 合约设计

### 4.1 状态

```solidity
uint256 public totalShares;       // 总份额
uint256 public totalReleased;     // 历史已发放总额

mapping(address => uint256) public shares;    // 每人的份额
mapping(address => uint256) public released;  // 每人已领的累计金额
address[] public payees;          // 受益人列表(便于遍历)
```

### 4.2 三个事件

```solidity
event PayeeAdded(address account, uint256 shares_);
event PaymentReleased(address to, uint256 amount);
event PaymentReceived(address from, uint256 amount);
```

### 4.3 业务流程

```
部署:
  constructor 传入 (payees, shares),内部循环 _addPayee
  ↓
持续收款(任意时刻多次):
  someone.call{value: X}(split.address) → 触发 receive() → emit PaymentReceived
  ↓
受益人取款:
  payee 调 release(payee) → 内部算 releasable(payee) → .call{value:} 转账
  ↓
继续收款 → 受益人再次 release(增量取走新增的份额)
```

### 4.4 累计模型 vs 流水模型

```
流水模型(错):每次收款就立刻按比例分掉
  → 接收方失败一笔,整个流程 revert,坏地址毁掉一切

累计模型(本课):合约累计收款,每人有"应得 vs 已领"
  → 接收方失败,只影响他自己,其他人继续 release
  → 中途可以加新收款,公式自动重新分配
```

## 5. 代码拆解

### 5.1 receive —— 接 ETH 不分配

```solidity
receive() external payable virtual {
    emit PaymentReceived(msg.sender, msg.value);
}
```
要点:
- 收到 ETH **只发事件,不分配** —— 分配在 `release()` 里被动触发
- 这就是"累计模型":钱堆在合约里,谁来取谁取

### 5.2 release —— 受益人主动领

```solidity
function release(address payable _account) public virtual {
    require(shares[_account] > 0, "PaymentSplitter: account has no shares");

    uint256 payment = releasable(_account);
    require(payment != 0, "PaymentSplitter: account is not due payment");

    totalReleased += payment;
    released[_account] += payment;
    (bool success,) = _account.call{value: payment}("");
    require(success, "Transfer failed");
    emit PaymentReleased(_account, payment);
}
```
要点:
- **任何人都可以代某个受益人调** —— 反正钱进的是受益人地址
- **先改状态,再转账**(Checks-Effects-Interactions),防重入
- 失败必须 revert(否则 `released` 已加但钱没到,下次取不到了)

### 5.3 计算公式 —— 累计模型的灵魂

```solidity
function releasable(address _account) public view returns (uint256) {
    uint256 totalReceived = address(this).balance + totalReleased;
    return pendingPayment(_account, totalReceived, released[_account]);
}

function pendingPayment(
    address _account,
    uint256 _totalReceived,
    uint256 _alreadyReleased
) public view returns (uint256) {
    return (_totalReceived * shares[_account]) / totalShares - _alreadyReleased;
}
```

举个例子(份额 user1:1 / user2:3,总 4):
```
1. 收 4 ETH:
   totalReceived=4, released[user1]=0
   pendingPayment(user1) = 4*1/4 - 0 = 1 ETH ✓

2. user1 取 1 ETH:
   released[user1]=1, totalReleased=1, balance=3
   pendingPayment(user1) = 3*1/4 - ... 等下,这不对!

   ←修正:totalReceived = balance + totalReleased = 3 + 1 = 4 ✓
   pendingPayment(user1) = 4*1/4 - 1 = 0 ✓(已经拿过了)

3. 再收 8 ETH:
   balance=11, totalReleased=1, totalReceived=12
   pendingPayment(user1) = 12*1/4 - 1 = 2 ETH ✓(分到 1/4 新增)
   pendingPayment(user2) = 12*3/4 - 0 = 9 ETH ✓(累计应得 9)
```

**`totalReceived = balance + totalReleased`** 这一行是 PaymentSplit 的灵魂 —— 它让公式在"持续收款"下保持正确。

### 5.4 _addPayee —— 初始化受益人

```solidity
function _addPayee(address _account, uint256 _accountShares) private {
    require(_account != address(0), "PaymentSplitter: account is the zero address");
    require(_accountShares > 0, "PaymentSplitter: shares are 0");
    require(shares[_account] == 0, "PaymentSplitter: account already has shares");

    payees.push(_account);
    shares[_account] = _accountShares;
    totalShares += _accountShares;
    emit PayeeAdded(_account, _accountShares);
}
```
三大 require:**非零地址、非零份额、无重复**。private 只在 constructor 中调用 —— **部署后无法增删受益人**(简化版,生产 PaymentSplitter 也是不可变的)。

### 5.5 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 代码量 | ~68 行 | ~67 行 |
| 逻辑 | 完全一致 | 完全一致 |
| 差别 | 合约名 `PaymentSplit` | 合约名 `PaymentSplitOZ` |

**本项目 oz 版没有"额外引入 OZ 库"**,只是把同样代码用 `OZ` 后缀命名,作为占位对比。**生产环境请使用 `@openzeppelin/contracts/finance/PaymentSplitter.sol`** —— 它额外支持 ERC20 分账。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/30_PaymentSplit
```

### 步骤 2:查看文件结构

```
src/
├── raw/PaymentSplit.sol     # 原生 PaymentSplit
└── oz/PaymentSplit.sol      # 同名 OZ 版(本项目里两版逻辑等价)
test/
├── raw/PaymentSplit.t.sol
└── oz/PaymentSplit.t.sol
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

### 步骤 5:重点测试 —— 按比例分配(`test/raw/PaymentSplit.t.sol`)

```solidity
function setUp() public {
    address[] memory payees = new address[](2);
    payees[0] = user1;
    payees[1] = user2;
    uint256[] memory shares = new uint256[](2);
    shares[0] = 1; shares[1] = 3;     // 1:3 份额
    split = new PaymentSplit(payees, shares);
}

function testReceivePayment() public {
    (bool success,) = address(split).call{value: 4 ether}("");
    require(success);
    assertEq(split.releasable(user1), 1 ether);   // 4 * 1/4 = 1
    assertEq(split.releasable(user2), 3 ether);   // 4 * 3/4 = 3
}

function testReleaseMultiple() public {
    (bool success,) = address(split).call{value: 4 ether}("");
    require(success);
    split.release(user1);
    split.release(user2);
    assertEq(user1.balance, 1 ether);
    assertEq(user2.balance, 3 ether);
}
```
教学点:`{value: 4 ether}("")` 给空 calldata + 有 ETH → 触发 `receive()` → emit `PaymentReceived` → 钱进合约累计。

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 7 个测试全部 PASS:
  - **raw**: `testInitialShares`、`testReceivePayment`、`testRelease`、`testReleaseMultiple`
  - **oz**: `testInitialShares`、`testReceivePayment`、`testRelease`

## 8. 常见错误排查

### 错误 1:`release(_account)` 报 "account is not due payment"

- **常见原因**:合约还没收到 ETH,或该 account 已把当前份额全部领完
- **解决步骤**:先 send ETH 给合约,再 release;或等下次收款后再来
- **验证方式**:`testReceivePayment` 先收 4 ether,确认 `releasable > 0` 才能 release

### 错误 2:`pendingPayment` 公式整数除法精度损失

- **常见原因**:`(totalReceived * shares) / totalShares` 当 `totalReceived * shares` 不能被 `totalShares` 整除时,会丢精度,导致每人累计领到的总和**小于**总收款
- **解决步骤**:把份额设为可整除的数(如 100 vs 1000 比 3 vs 7 友好);或在 release 时,如果 `totalReleased == totalReceived` 则把余数补给最后一个领的人
- **验证方式**:用 7 ether ÷ 份额 1:3,验证两人 release 后合约里剩 1 wei(`7 - 1 - 5 = 1`)

### 错误 3:部署后想加一个受益人,发现没有 `addPayee` 外部函数

- **常见原因**:本课的 PaymentSplit 不可变,只在 constructor 中调 `_addPayee`
- **解决步骤**:重新部署一个,或在生产用 OZ `PaymentSplitter` 的可升级变体
- **验证方式**:这是设计选择 —— 不可变保证受益人不会被恶意添加

### 错误 4:用 `.transfer()` 替代 `.call{value:}` 导致部分受益人收不到

- **常见原因**:`.transfer()` 只给 2300 gas,受益人是合约且 fallback 重时会失败
- **解决步骤**:用 `.call{value: payment}("")` + `require(success)`
- **验证方式**:写一个故意 fallback 中 SSTORE 的接收合约,确认能用 `.call` 收到

## 9. 本节总结

- PaymentSplit 用**累计模型**:钱堆合约,谁来取谁取,公式自动按比例
- 灵魂公式:`(totalReceived * shares[user]) / totalShares - released[user]`
- `totalReceived = balance + totalReleased` 是保证公式在持续收款下正确的关键
- 部署后受益人**不可变**(简化设计,符合 OZ 标准)
- 用 `.call{value:}` 退 ETH,不要用 `.transfer`
- 生产环境直接用 OZ `PaymentSplitter`(支持 ERC20 + ETH 双通道)

## 10. 课后练习

### 练习 1
为 PaymentSplit 添加 **ERC20 分账**:
- 加 `mapping(address => mapping(address => uint256)) public erc20Released;` //  (token, account) -> released
- 加 `mapping(address => uint256) public totalErc20Released;` // token -> totalReleased
- 加 `function release(IERC20 token, address account) external` —— 同样公式但用 ERC20
- 加测试:mint 1000 USDT 给合约,两人按 1:3 各领 250 / 750

### 练习 2
为 PaymentSplit 实现 **可分润的 NFT 包装**:
- 部署一个特殊 NFT(每个 tokenId = 一份股份)
- 持有 NFT 的人才能调 `release` 领分润
- 转让 NFT = 转让分润权
- 加测试:Alice mint tokenId=0,收 4 ether 后 release 拿 1 ether;转让给 Bob,Bob 再 release 应空(因 released 跟着 tokenId 但旧 owner 已领)

### 练习 3(进阶)
对比 OZ 官方 `PaymentSplitter`:
- 阅读 `@openzeppelin/contracts/finance/PaymentSplitter.sol` 源码
- 列出与本课 raw 版的至少 3 处差异(提示:OZ 同时支持 ERC20、用 `Address.sendValue` 而非 `.call`、用 `_PaymentSplitter_init` 等)
- 在 README 中写一节"PaymentSplit vs OZ PaymentSplitter 对比"
