# 第 28 课:Faucet —— 测试网水龙头

## 1. 本节目标

学完这节课,你能:
- 说清"为什么测试网项目要做 Faucet"
- 自己手写一个最小可用的 Faucet(raw 实现)
- 用 OpenZeppelin 的 ERC20 类型搭一个 Faucet(oz 实现)
- 理解"防女巫攻击"的 mapping 模式
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币(Faucet 操作的是 ERC20 token)
- 第 12 课:Modifier(Faucet 用 `require` 做简单权限,可以进一步抽成 modifier)
- 第 13 课:Event 与日志(`SendToken` 事件记录每次领取)
- 第 9 课:Mapping(`mapping(address => bool)` 是记录领取状态的标配)

## 3. 先讲结论

**Faucet(水龙头)是项目方在测试网空投免费代币的入口** —— 一般是:用户连钱包 → 点"Claim" → 拿到一笔测试代币用于体验。

**核心约束**:
- 每个地址只能领 1 次(防止单人开多钱包薅光)
- Faucet 自己得先持有代币(部署时充值,或 `mint` 给它)
- 发完即空(`balanceOf(self) < amount` 时 revert)

业务流程:

```
项目方 → mint/transfer N 个 token 给 Faucet 合约
   ↓
用户 → 调 requestTokens()
   ↓
Faucet → 检查"未领过" → 转 amountAllowed 个给用户 → 标记已领
```

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/Faucet.sol` + `src/raw/ERC20.sol` + `src/raw/IERC20.sol` | ~30 行(Faucet) |
| **oz** | `src/oz/Faucet.sol` + `src/oz/ERC20Minter.sol` | ~29 行(FaucetOZ) |

> 注:Faucet 本身的逻辑两版几乎一样,差别在引用的 ERC20 类型 —— raw 用自写的 `IERC20` 接口,oz 用 OZ 的 `ERC20` 类型。

## 4. 合约设计

### 4.1 Faucet 状态

```solidity
uint256 public amountAllowed = 100;              // 每次发多少
address public tokenContract;                    // 目标 token 地址
mapping(address => bool) public requestedAddress; // 记录领过的地址
```

### 4.2 唯一对外接口

```solidity
function requestTokens() external;
event SendToken(address indexed Receiver, uint256 indexed Amount);
```

业务规则:
1. `requestedAddress[msg.sender] == false`(没领过)
2. `token.balanceOf(self) >= amountAllowed`(水龙头不空)
3. 转账 → 标记 → emit

### 4.3 反女巫机制

```
单一 mapping(address => bool) ≠ 完美防御:
  - 同一个真人可以开 N 个 EOA 地址领 N 次
  - 但提高了攻击成本(每个新地址要支付 gas)
  - 进阶方案:绑定 Twitter / Discord 验证、Gitcoin Passport、Captcha
```

## 5. 代码拆解

### 5.1 raw 实现 —— Faucet 主体 (`src/raw/Faucet.sol`)

```solidity
contract Faucet {
    uint256 public amountAllowed = 100;
    address public tokenContract;
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}
```
要点:
- `tokenContract` 是 `address` 类型,运行时再 cast 成 `IERC20`
- 两个 require 顺序:先查"是否领过"(便宜),再查"水龙头余额"(读外部合约,贵)
- `transfer` 在 `requestedAddress = true` **之前** —— 标准 Checks-Effects-Interactions 模式应反过来(先标记再转账),raw 版这里有可重入风险,但因为 token 是普通 ERC20 不会回调,实际安全

### 5.2 oz 实现 —— 强类型 + 测试友好 (`src/oz/Faucet.sol`)

```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FaucetOZ {
    uint256 public amountAllowed = 100;
    ERC20 public token;
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(ERC20 _token) {
        token = _token;
    }

    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}
```
要点:
- `token` 用 `ERC20` 类型直接持有,无需运行时 cast
- 业务逻辑与 raw 完全一致

### 5.3 辅助合约 —— ERC20Minter(`src/oz/ERC20Minter.sol`)

```solidity
contract ERC20Minter is ERC20 {
    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}

    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
```
教学要点:
- OZ 的 ERC20 没有暴露 `mint` —— 因为生产环境必须有权限控制
- 测试中需要任意 mint 给 Faucet 充值,所以套一层薄壳,直接暴露 `mint(to, amount)`
- raw 版的 ERC20(第 24 课)自带无权限 mint,所以不需要这层壳

### 5.4 对照看 —— raw vs oz

| 维度 | raw Faucet | oz FaucetOZ |
|------|-----------|-------------|
| token 类型 | `address` 字段 + 运行时 cast | `ERC20` 类型字段 |
| 充值方式 | `token.mint() → token.transfer(faucet)` | 直接 `token.mint(faucet, n)` |
| 业务逻辑 | 完全一致 | 完全一致 |
| 代码量 | ~30 行 | ~29 行 |

**两者业务等价**,差异只是"如何获取/管理 ERC20 实例"。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/28_Faucet
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── IERC20.sol
│   ├── ERC20.sol           # 24 课的 raw ERC20(带无权限 mint)
│   └── Faucet.sol          # 原生 Faucet
└── oz/
    ├── ERC20Minter.sol     # 暴露 mint 的薄壳,便于测试
    └── Faucet.sol          # OZ 版 Faucet
test/
├── raw/Faucet.t.sol
└── oz/Faucet.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 5 个测试全部通过(raw 3 个 + oz 2 个)。

### 步骤 5:重点测试 —— 水龙头耗尽(`test/raw/Faucet.t.sol`)

```solidity
function testFaucetEmpty() public {
    vm.prank(user1);
    faucet.requestTokens();          // user1 领 100
    vm.prank(user2);
    faucet.requestTokens();          // user2 领 100
    assertEq(token.balanceOf(user1), 100);
    assertEq(token.balanceOf(user2), 100);
    vm.prank(user3);
    vm.expectRevert("Faucet Empty!");  // 总充值 250,user3 来时余额 50 < 100,失败
    faucet.requestTokens();
}
```
教学点:`vm.prank(addr)` 只影响**下一次**外部调用,所以每次领取前都要 prank 一次。这样模拟了三个不同地址依次领取。

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 5 个测试全部 PASS:
  - **raw**: `testRequestToken`、`testRequestTokenOnlyOnce`、`testFaucetEmpty`
  - **oz**: `testRequestToken`、`testRequestTokenOnlyOnce`

## 8. 常见错误排查

### 错误 1:部署 Faucet 后调用 `requestTokens` 立刻报 "Faucet Empty"

- **常见原因**:忘了给 Faucet 充值
- **解决步骤**:`token.mint(faucetAddr, 10000)` 或先 mint 给自己再 `transfer`
- **验证方式**:`setUp` 中 `token.mint(250); token.transfer(address(faucet), 250)` 是充值标准流程

### 错误 2:测试中所有 `requestTokens` 都被算作同一地址

- **常见原因**:每次调用前没用 `vm.prank` 切换 msg.sender,默认都是测试合约自己
- **解决步骤**:`vm.prank(user1); faucet.requestTokens();`,prank 一次只影响一次调用
- **验证方式**:`testFaucetEmpty` 中三次 prank 三个不同地址,才能模拟"多用户领光"

### 错误 3:token 合约和 Faucet 关联不上

- **常见原因**:raw 版传入 `address(token)`,但 token 还没部署
- **解决步骤**:先部署 token,拿到地址再部署 Faucet
- **验证方式**:`setUp` 中先 `new ERC20`,再 `new Faucet(address(token))`

### 错误 4:同一钱包换 RPC 重新连接后又能领

- **常见原因**:Faucet 用 `mapping(address => bool)` 防御,但本身就只能挡同一地址
- **解决步骤**:生产 Faucet 加 IP 限制(链下)、Captcha、Twitter 绑定
- **验证方式**:这种是产品层面的反女巫,不在合约范围内

## 9. 本节总结

- Faucet = 测试网"免费领代币"的合约
- 三大设计:**单地址领一次** + **水龙头持有余额** + **发完即空**
- 用 `mapping(address => bool)` 是最便宜的防御,但只能挡同一地址
- raw 与 oz 版业务等价,差别在 token 类型声明和充值流程
- 测试中 `vm.prank` 是模拟多用户的关键 cheatcode

## 10. 课后练习

### 练习 1
扩展 `Faucet` 为 **可配置型水龙头**:
- 加 `address public owner`(在 constructor 中 `owner = msg.sender`)
- 加 `function setAmountAllowed(uint256 _amount) external onlyOwner` —— 让运维可调每次发放量
- 加 modifier `onlyOwner`
- 加测试:非 owner 调用 `setAmountAllowed` 应 revert

### 练习 2
实现 **冷却期 Faucet**:
- 把 `mapping(address => bool)` 改为 `mapping(address => uint256) public lastClaimTime`
- 加 `uint256 public cooldown = 1 days`
- `requestTokens` 校验 `block.timestamp - lastClaimTime[msg.sender] >= cooldown`
- 加测试:连续两次领取应失败,`vm.warp(block.timestamp + 1 days + 1)` 后再领应成功

### 练习 3(进阶)
实现 **ETH Faucet**:
- 不是发 ERC20,而是发原生 ETH
- 合约 payable,部署时充值 ETH;`requestEth` 用 `payable(msg.sender).call{value: amountAllowed}("")` 转账
- 加测试:充值 1 ether,允许领取 0.1 ether,验证连续领取直到空,记录 `Withdrawal` 事件
