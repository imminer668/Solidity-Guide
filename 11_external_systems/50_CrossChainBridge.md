# 第 50 课:CrossChainBridge —— 跨链桥

## 1. 本节目标

学完这节课,你能:
- 说清"为什么以太坊 + Polygon 之间需要跨链桥"
- 自己手写一个支持 burn/mint + lock/unlock 双模式的 SimpleBridge(raw 实现)
- 区分跨链桥两种核心模式:**burn/mint** vs **lock/unlock**
- 理解为什么跨链桥是 DeFi 黑客最爱攻击的目标
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20(跨链桥本质是跨链 ERC20 转移)
- 第 25 课:Ownable(bridge owner 是中继角色)
- 第 17 课:合约调用(中继器调 mint/unlock)

## 3. 先讲结论

**CrossChainBridge(跨链桥) = 在 A 链锁/烧资产,在 B 链铸/解资产,达到"等价跨链转移"效果**。典型场景:
- **资产跨链**:ETH 主网 → Polygon / Arbitrum / Optimism
- **稳定币桥**:USDC 用 Circle CCTP 实现 burn-mint
- **NFT 跨链**:OpenSea / LayerZero ONFT
- **协议跨链调用**:Stargate 让 Curve LP 跨链

**跨链桥本课重点:这是一门复合课**

- **共识**:以太坊和 Polygon 各自独立,**不互相验证** → 需要"信任中继者"
- **桥的核心**:在源链证明"我烧/锁了资产" + 在目标链根据证明"铸/解资产"
- **本课用 owner 模拟中继者**(教学版),实际生产用更复杂方案

**两种核心模式**:

| 模式 | 源链行为 | 目标链行为 | 总供应量 | 适用 |
|------|---------|----------|--------|------|
| **burn/mint** | burn 资产 | mint 等量 | 总和不变(各链 burn + mint 抵消) | 同一代币跨链(USDC、CCT) |
| **lock/unlock** | lock 到合约 | mint wrapped 代币 | 源链锁定 = 目标链流通 | wrapped 资产(WETH、wBTC) |

教学要点:
- burn/mint:**适合同一代币**(如 USDC 主网和 Polygon 是同一种 USDC)
- lock/unlock:**适合"原生 vs 包装"**(如 ETH → Polygon 上的 wETH)

**为什么跨链桥是 DeFi 黑客最爱?**

- **2022 年 7 大跨链桥被盗事件,损失超 20 亿美元**
- Ronin 桥被盗 6.25 亿(私钥泄露)、Wormhole 被盗 3.2 亿(签名验证 bug)、Nomad 桥被盗 1.9 亿(初始化 bug)
- 原因:**信任假设强**(依赖中继者/多签);**升级权限大**(可铸无限假代币);**链下逻辑复杂**(链下验证一旦失误,链上无法回滚)

**核心流程(burn/mint 模式)**:

```
源链(以太坊):
  用户 → bridge.burn(100 CCT) → 烧 100 CCT,emit Bridge(user, 100)
   ↓
中继者监听 Bridge 事件
   ↓
目标链(Polygon):
  中继者 → bridge.mint(user, 100) → mint 100 CCT 给用户
   ↓
用户在 Polygon 上拿到 100 CCT(总供应量不变)
```

**核心流程(lock/unlock 模式)**:

```
源链(以太坊):
  用户 → bridge.lock(100 CCT) → 100 CCT 锁到 bridge 合约,emit Lock(user, 100)
   ↓
中继者监听 Lock 事件
   ↓
目标链(Polygon):
  中继者 → bridge.mint(user, 100) → mint 100 wCCT 给用户
   ↓
用户在 Polygon 上拿到 100 wCCT(源链总供应量不变,但 bridge 合约持有 100)
   ↓
用户想跨回:
  目标链 burn wCCT → 中继 → 源链 unlock 给用户
```

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/SimpleBridge.sol`(基于 OZ ERC20 + Ownable) | 79 行 |
| **oz** | `src/oz/SimpleBridge.sol` | 11 行(占位) |

> 注:本项目 raw 版直接基于 OZ ERC20 + Ownable,oz 版仅为命名占位。**生产环境**用 LayerZero / Wormhole / Axelar / Circle CCTP 等专业跨链协议。

## 4. 合约设计

### 4.1 SimpleBridge 继承

```solidity
contract SimpleBridge is ERC20, Ownable {
    // ERC20:代币功能
    // Ownable:中继者权限(本课用 owner 模拟)
}
```

要点:bridge 合约本身就是代币合约(简化模型),实际生产中 bridge 和 token 通常分开。

### 4.2 四个事件

```solidity
event Bridge(address indexed user, uint256 amount);   // 跨链转账触发(burn/lock 都 emit)
event Mint(address indexed to, uint256 amount);        // 目标链铸造
event Lock(address indexed user, uint256 amount);      // 锁定
event Unlock(address indexed user, uint256 amount);    // 解锁
```

教学点:Bridge 事件是中继者监听的关键 —— 中继器扫描源链所有 Bridge 事件,在目标链触发 Mint。

### 4.3 burn / mint(burn/mint 模式)

```solidity
function burn(uint256 amount) external {
    _burn(msg.sender, amount);
    emit Bridge(msg.sender, amount);
}

function mint(address to, uint256 amount) external onlyOwner {
    _mint(to, amount);
    emit Mint(to, amount);
}
```

要点:
- 任何人都能 burn(用自己的钱)
- 只有 owner(中继者)能 mint(防伪造)
- burn 时 emit `Bridge` 事件给中继器监听

### 4.4 lock / unlock(lock/unlock 模式)

```solidity
function lock(uint256 amount) external {
    _transfer(msg.sender, address(this), amount);
    emit Lock(msg.sender, amount);
    emit Bridge(msg.sender, amount);
}

function unlock(address to, uint256 amount) external onlyOwner {
    _transfer(address(this), to, amount);
    emit Unlock(to, amount);
}
```

要点:
- `_transfer(msg.sender, address(this))`:把资产转到 bridge 合约持有(不烧)
- unlock 同样仅 owner 可调
- `getLockedBalance()` 查 bridge 合约的余额 = 锁定总量

### 4.5 业务流程(完整跨链)

```
模式 1:burn/mint
  以太坊:user.burn(100) → CCT 总供应 -100,emit Bridge(user, 100)
       ↓ 中继监听
  Polygon:owner.mint(user, 100) → CCT 总供应 +100,emit Mint(user, 100)
       ↓ 总和不变

模式 2:lock/unlock
  以太坊:user.lock(100) → 100 CCT 在 bridge 合约持有,emit Lock(user, 100) + Bridge(user, 100)
       ↓ 中继监听
  Polygon:owner.mint(user, 100) → 100 wCCT 给用户
       ↓ 用户想跨回
  Polygon:user.burn(100) → wCCT 销毁
       ↓ 中继监听
  以太坊:owner.unlock(user, 100) → 100 CCT 还给用户
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/SimpleBridge.sol`(79 行)

```solidity
contract SimpleBridge is ERC20, Ownable {
    constructor(string memory name, string memory symbol, uint256 totalSupply)
        payable ERC20(name, symbol) Ownable(msg.sender) {
        _mint(msg.sender, totalSupply);
    }
    
    function burn(uint256 amount) external { ... }
    function mint(address to, uint256 amount) external onlyOwner { ... }
    function lock(uint256 amount) external { ... }
    function unlock(address to, uint256 amount) external onlyOwner { ... }
    function getLockedBalance() external view returns (uint256) {
        return balanceOf(address(this));
    }
}
```

要点:
- 部署时 owner 拿到全部 totalSupply
- 同一个合约支持 burn/mint **和** lock/unlock 两种模式

### 5.2 oz 实现 —— `src/oz/SimpleBridge.sol`

```solidity
import {SimpleBridge} from "../../src/raw/SimpleBridge.sol";

contract SimpleBridgeOZ is SimpleBridge {
    constructor() SimpleBridge("CrossChain Token OZ", "CCTOZ", 10000 ether) {}
}
```

要点:业务完全一致,本项目 oz 版只是命名占位。

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 完整 burn/mint + lock/unlock | 继承 raw |
| 代码量 | 79 行 | 11 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 LayerZero / Wormhole / Axelar / CCTP**:
- **LayerZero**:通用消息层(任意合约可跨链调用)
- **Wormhole**:Guardian 网络多签
- **Axelar**:通用消息 + DEX
- **Circle CCTP**:USDC 官方,真正 burn/mint(非 wrapped)

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/11_external_systems/50_CrossChainBridge
```

### 步骤 2:查看文件结构

```
src/
├── raw/SimpleBridge.sol      # 79 行,burn/mint + lock/unlock
└── oz/SimpleBridge.sol       # 11 行,继承 raw
test/
├── raw/SimpleBridge.t.sol    # 12 个测试
└── oz/SimpleBridge.t.sol     # 1 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 13 个测试全部通过(raw 12 个 + oz 1 个)。

### 步骤 5:重点测试 —— burn/mint 完整流程(`test/raw/SimpleBridge.t.sol`)

```solidity
function test_BurnAndMint() public {
    bridge.transfer(user, 100 ether);                  // 给 user 转 100
    
    vm.prank(user);
    bridge.burn(50 ether);                              // user 烧 50
    
    assertEq(bridge.totalSupply(), 10000 ether - 50 ether);   // 总供应 -50
    assertEq(bridge.balanceOf(user), 50 ether);                // user 剩 50
}

function test_BridgeEvent() public {
    bridge.transfer(user, 100 ether);
    vm.prank(user);
    
    vm.expectEmit(true, true, true, true);             // 校验所有 indexed 字段
    emit Bridge(user, 50 ether);
    bridge.burn(50 ether);                              // 触发 Bridge 事件
}
```

教学点:
- `vm.expectEmit(true, true, true, true)`:4 个 true 表示校验 4 个字段(topic1/topic2/topic3/data)
- Bridge 事件是中继器监听的关键

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 13 个测试全部 PASS:
  - **raw**: 12 个,覆盖 burn/mint/lock/unlock/事件/Owner权限
  - **oz**: 1 个占位测试

## 8. 常见错误排查

### 错误 1:用户调 mint 成功(没鉴权)

- **常见原因**:mint 漏写 `onlyOwner` modifier
- **解决步骤**:mint/unlock 都必须 `onlyOwner`,只有中继者能调
- **验证方式**:`test_OnlyOwnerCanMint` 用非 owner 调 mint,vm.expectRevert

### 错误 2:跨链后用户没收到 wrapped 资产

- **常见原因**:中继器没监听 Bridge 事件,或监听错链
- **解决步骤**:中继器订阅源链 Bridge 事件,过滤 user/amount 字段后调目标链 mint
- **验证方式**:测试中模拟"burn → 监听事件 → mint",验证用户余额

### 错误 3:lock 时合约余额没变

- **常见原因**:用了 `transferFrom` 而非 `_transfer`,且 user 没 approve
- **解决步骤**:本课用 `_transfer`(internal),不需要 approve;或用 `transferFrom` + approve 流程
- **验证方式**:`test_LockAndUnlock` 验证 bridge 合约余额涨

### 错误 4:跨链桥被黑无限铸代币

- **常见原因**:中继者私钥被盗 / 签名验证 bug / 升级权限被滥用
- **解决步骤**:
  - 中继者用多签(48 课)
  - 加每日 mint 上限(rate limit)
  - 加 timelock(33 课)防 owner 紧急操作
- **验证方式**:压测 owner 紧急 mint 时,是否被 timelock 阻挡

## 8.5 本课安全边界

> 集中安全知识见第 20 课(常见漏洞与防护),本节只列**与跨链桥 / Bridge 直接相关**的坑点。跨链桥是 DeFi 黑客最爱目标,2022 年损失 20+ 亿美元,本节必须看。

### 坑 1:中继者单点失误 = 无限铸

**现象**:SimpleBridge 把 `mint / unlock` 标为 `onlyOwner`,owner 是普通 EOA。一旦 owner 私钥泄漏:
- 攻击者调 `mint(user, 1000000 ether)` → 凭空铸 100 万代币
- 用户拿这些代币换走所有真实资产
- **本课 50 line 309 错误排查里已经点过**

**修复**:
- **多签钱包**(48 课):owner 改为 Gnosis Safe,5-of-9 签名
- **MPC**(如 LayerZero / Wormhole 的 Validator 网络)
- **Timelock**(33 课):紧急操作延迟 24-48 小时,社区有时间反应

### 坑 2:无 mint 速率限制 = 攻击窗口期长

**现象**:owner 即使是多签,被黑后攻击者可以**一次性 mint 巨额**。多签是 5 个人,2-3 个恶意即可 → **1 笔交易 = 全部铸出**。

**修复**:
```solidity
uint256 public dailyMintCap = 1_000_000 ether;
mapping(uint256 => uint256) public dailyMinted;  // day => amount

modifier rateLimited(uint256 amount) {
    uint256 today = block.timestamp / 1 days;
    dailyMinted[today] += amount;
    require(dailyMinted[today] <= dailyMintCap, "Rate limited");
    _;
}

function mint(address to, uint256 amount) external onlyOwner rateLimited(amount) { ... }
```

本课练习 2 就是这个模式。

### 坑 3:burn/mint 守恒未校验

**现象**:源链 burn 100,目标链 mint 100(总供应 +100)。如果中继器在源链 burn 事件还没最终性时(Ethereum 还没 final)就 mint 目标链 → 源链 reorg → **目标链多发 100**。

**修复**:
- **等待源链最终性**(Ethereum 64 区块 ≈ 12 分钟)
- **跨链消息带 sourceChainId + sourceBlockNumber + sourceTxHash**,目标链验
- 用 LayerZero / Wormhole 这类专业协议(自带最终性检查)

### 坑 4:重放攻击(同一笔 burn 在多链 replay)

**现象**:Alice 在源链 A burn 100,中继到目标链 B mint 100。如果中继器**同时把这条消息发给 C 链**(同地址同 selector 合约),C 链也 mint 100 → Alice 凭空多拿 100。

**修复**:
- **跨链消息带唯一 ID**(源链 txHash + logIndex)
- 目标链记录已用 ID(`mapping(bytes32 => bool) public processed`),replay 时 revert

### 坑 5:lock/unlock 模式 — 源链 token 被锁死

**现象**:lock/unlock 模式下,目标链的 wrapped token 流通,源链的"原始 token"被锁在 bridge 合约。如果:
- bridge 合约有 bug → 没人能 unlock
- 源链 fork / 主网升级 → 锁定的 token 永久锁死

**修复**:
- **锁定的 token 总量 = 目标链 wrapped 流通量**(链上可校验:`balanceOf(bridge) == wrappedTotalSupply`)
- 紧急 unlock 机制(多签可触发)
- 用 **CCTP**(Circle 官方):不锁定,真 burn/mint,无 wrapped 资产

### 坑 6:中继者劫持源链最终性证明

**现象**:中继器"信任"地传入源链 burn 事件,但攻击者控制了源链 validator(或源链本身是 sidechain),可以**伪造 burn 事件**:
1. 攻击者在源链 A 发"虚假 burn 100"的日志(自己能造)
2. 中继器没真验 merkle proof,直接把这条日志喂给目标链 B
3. 目标链 B mint 100,但源链 A **实际没有 burn**

**修复**:
- 中继器必须用**链上验证**(Light Client / ZK Proof)
- 简化:中继器是"信任源链的" + 假设源链 fork 选择合理
- 生产:LayerZero 的 Oracle + Relayer,或 Wormhole 的 Guardian 多签

### 坑 7:紧急暂停机制缺失

**现象**:发现被黑,owner 想暂停 mint,但合约没 `pause` 函数 → **无法止损**。

**修复**:
- 加 `Pausable`(OZ),`whenNotPaused` 修饰 mint/unlock
- 触发:`pause()` 锁定桥,等修复后 `unpause()`

### 关键防御清单

| 风险 | 防御 |
|------|------|
| 中继者单点失误 | 多签 / MPC / 链上验证 |
| mint 速率无限制 | 每日 mint cap |
| burn/mint 不守恒 | 等源链最终性 + 跨链 ID 防 replay |
| 跨链重放 | 跨链消息带 unique ID,记录已用 |
| wrapped 锁死 | 锁仓总量链上校验,紧急 unlock |
| 源链最终性 | Light Client / ZK / 等多区块 |
| 无紧急暂停 | `Pausable` + 治理触发 |

> 跨链桥安全是 DeFi 顶级难题,生产方案( LayerZero / Wormhole / Axelar / CCTP)需要数月审计 + 持续升级。

## 9. 本节总结

- 跨链桥 = 源链 burn/lock + 目标链 mint/unlock 的"等价跨链"
- 两种模式:
  - **burn/mint**:同一代币跨链(USDC、CCT),总供应不变
  - **lock/unlock**:原生 ↔ 包装(ETH ↔ wETH),源链锁定 = 目标链流通
- 信任假设:依赖中继者(本课 owner),生产用多签/Guardian/MPC
- 跨链桥是 DeFi 黑客最爱,**2022 年损失 20+ 亿美元**
- 防御:多签中继 + rate limit + timelock + 公开审计
- 配合 ERC20Permit(37 课):用户离线签名授权 lock,减少 gas
- 配合 MultisigWallet(48 课):中继者多签
- 实战:LayerZero / Wormhole / Axelar / Circle CCTP 是生产方案
- 写 Bridge 最常踩的坑:中继者单点、mint 无上限、跨链重放、wrapped 锁死、无暂停机制

## 10. 课后练习

### 练习 1
为 SimpleBridge 加 **签名验证 mint**:
- 把 owner 改为多个中继者 `address[] public relayers`
- mint 需要 M-of-N 中继者签名(用 48 课的 MultisigWallet 风格)
- 加测试:1 个中继者签名 mint 失败,2 个签名成功

### 练习 2
为 SimpleBridge 加 **每日 mint 上限**:
- 加 `uint256 public dailyMintCap = 1000 ether;`
- 加 `mapping(uint256 => uint256) public dailyMintedAmount;`(day => amount)
- mint 时校验 `dailyMintedAmount[今天] + amount <= dailyMintCap`
- 加测试:超过上限 mint revert,新一天后重置

### 练习 3(进阶)
基于 raw 的 SimpleBridge,实现 **双向跨链(burn-mint 双向)**:
- 加 `function bridgeBack(uint256 amount) external` 反方向 burn + emit
- owner 监听后调 unlock 还原资产
- 加测试:user 双向跨链 100 次,源/目标链总供应始终守恒
- 提示:这是 Stargate / LayerZero 的核心模式
