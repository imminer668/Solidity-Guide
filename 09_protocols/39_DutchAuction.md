# 第 39 课:DutchAuction —— 荷兰式价格衰减拍卖

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 NFT 发行/IDO 喜欢用荷兰拍卖(价格从高到低)"
- 自己手写一个价格线性衰减的 DutchAuction(raw 实现)
- 理解 `getAuctionPrice` 三段式逻辑(未开始 / 进行中 / 已结束)
- 区分荷兰拍卖(本课)与英式拍卖(价高者得,价往上走)
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 25 课:ERC721 非同质化代币(本课铸造 NFT)
- 第 14 课:Eth 与 fallback(`msg.value` 接收 ETH,找零)
- 第 16 课:时间戳与区块(`vm.warp` 推进时间)

## 3. 先讲结论

**DutchAuction(荷兰式拍卖) = 价格从高到低线性下降,谁先买谁得**。典型场景:
- **NFT 发行**:Azuki、ParaSpace 等都用荷兰拍卖首发
- **Token IDO**:新代币发行,起始价高、随时间衰减
- **OpenSea Dutch auctions**:NFT 一口价拍卖,价随时间降
- **域名拍卖**:ENS 短域名常用

**为什么用荷兰拍卖而不是英式拍卖?**
- 英式拍卖:价低到高,慢(数天),最后 5 分钟可能"狙击"
- 荷兰拍卖:价高到低,**快速成交** —— 早期付高溢价,晚期付低价
- **公平**:所有买家面对"同价先得",无最后出价博弈
- **对项目方友好**:早买的人多付 → 多融资

**价格衰减公式**:

```
if (now < start)               → START_PRICE        (还没开始)
else if (now >= start + TIME)  → END_PRICE          (已结束,地板价)
else:
    steps = (now - start) / DROP_INTERVAL
    price = START_PRICE - steps * DROP_PER_STEP    (线性下降)
```

举栗:START=1ETH,END=0.1ETH,TIME=10min,DROP_INTERVAL=1min
- t=0:1.0 ETH
- t=2min:0.82 ETH (1.0 - 2*0.09)
- t=5min:0.55 ETH
- t=10min:0.1 ETH
- t>10min:0.1 ETH(地板)

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/DutchAuction.sol` | ~78 行 |
| **oz** | `src/oz/DutchAuction.sol` | ~10 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 加 OZ 后缀(因 raw 已用 OZ `Ownable`,业务等价)。**生产环境**:用 OZ `Ownable` + `ERC721` + 自写价格衰减逻辑。

## 4. 合约设计

### 4.1 5 个 constant 拍卖参数

```solidity
uint256 public constant COLLECTION_SIZE = 10000;          // NFT 总数
uint256 public constant AUCTION_START_PRICE = 1 ether;     // 起始价
uint256 public constant AUCTION_END_PRICE = 0.1 ether;     // 地板价
uint256 public constant AUCTION_TIME = 10 minutes;         // 拍卖时长
uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes; // 每多少秒降一次

uint256 public constant AUCTION_DROP_PER_STEP =            // 每次降多少
    (AUCTION_START_PRICE - AUCTION_END_PRICE) /
    (AUCTION_TIME / AUCTION_DROP_INTERVAL);
// = 0.9 ether / 10 = 0.09 ether
```

要点:
- `constant` 编译期计算,`AUCTION_DROP_PER_STEP` 在源码中由公式算出
- 5 个参数定死后,**价格曲线就完全确定**了

### 4.2 业务流程

```
部署:
  auctionStartTime = block.timestamp
   ↓
价格衰减(任何人都能 query getAuctionPrice())
   ↓
用户 auctionMint{value: cost}(quantity):
  1. require(auctionStartTime != 0 && now >= auctionStartTime)
  2. require(totalSupply + quantity <= COLLECTION_SIZE)
  3. totalCost = getAuctionPrice() * quantity
  4. require(msg.value >= totalCost)
  5. for i: _mint(msg.sender, totalSupply())   ← 铸造 NFT
  6. if msg.value > totalCost: 找零
   ↓
项目方:withdrawMoney() 取走 ETH
```

### 4.3 关键设计选择

- **startTime 单独存**:`uint256 public auctionStartTime`,owner 可调
  - 部署时设"现在"(`auctionStartTime = block.timestamp`)
  - 项目方想推后开拍:`setAuctionStartTime(futureTime)` 一次性设置
- **找零机制**:`if (msg.value > totalCost) { transfer(msg.value - totalCost) }` —— 多付自动退
- **withdraw 模式**:ETH 累积在合约里,owner 主动 withdraw(避免每次 mint 都触发转账)

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/DutchAuction.sol`

#### getAuctionPrice:三段式
```solidity
function getAuctionPrice() public view returns (uint256) {
    if (block.timestamp < auctionStartTime) {
        return AUCTION_START_PRICE;                        // 阶段 1:未开始
    } else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
        return AUCTION_END_PRICE;                          // 阶段 2:已结束
    } else {
        uint256 steps = (block.timestamp - auctionStartTime) / AUCTION_DROP_INTERVAL;
        return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);  // 阶段 3:线性衰减
    }
}
```

教学点:
- **第一段 `< start`**:返回**起始价**(注意:不是 0,因为如果 `setAuctionStartTime` 推到未来,用户调 mint 也能看到"我得付 1 ETH")
- **第二段 `>= start + TIME`**:返回**地板价**(防止衰减超出范围)
- **第三段**:线性插值,`steps * DROP_PER_STEP` 算出"已经降了多少"

#### auctionMint:校验 + 铸造 + 找零
```solidity
function auctionMint(uint256 quantity) external payable {
    uint256 _saleStartTime = uint256(auctionStartTime);
    require(_saleStartTime != 0 && block.timestamp >= _saleStartTime, "sale has not started yet");
    require(totalSupply() + quantity <= COLLECTION_SIZE, "not enough remaining ...");

    uint256 totalCost = getAuctionPrice() * quantity;
    require(msg.value >= totalCost, "Need to send more ETH.");

    for (uint256 i = 0; i < quantity; i++) {
        uint256 mintIndex = totalSupply();
        _mint(msg.sender, mintIndex);
    }

    if (msg.value > totalCost) {
        payable(msg.sender).transfer(msg.value - totalCost);   // 找零
    }
}
```

要点:
- `totalCost = price * quantity` 价格实时计算
- 多付自动找零(用 `transfer` 给合约调用者)
- 找零只用 2300 gas,简单安全

#### withdrawMoney:owner 取 ETH
```solidity
function withdrawMoney() external onlyOwner {
    (bool success, ) = msg.sender.call{value: address(this).balance}("");
    require(success, "Transfer failed.");
}
```

要点:
- `payable(msg.sender).call{value: balance}("")` 一次取走所有
- 用 `.call` 而非 `.transfer` —— 后者 gas 限制(2300)可能让合约 owner 收不到

### 5.2 oz 实现 —— `src/oz/DutchAuction.sol`

```solidity
import {DutchAuction as DutchAuctionRaw} from "../../src/raw/DutchAuction.sol";

contract DutchAuctionOZ is DutchAuctionRaw {
    constructor() DutchAuctionRaw() {}
}
```

要点:
- 业务完全一致
- 本项目 oz 版只是"加 OZ 后缀"

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| Ownable | 引入 OZ `Ownable` | 继承 raw |
| 代码量 | ~78 行 | ~10 行 |
| 适用 | 学原理 | 命名风格占位 |

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/09_protocols/39_DutchAuction
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── ERC721.sol            # 25 课的 raw ERC721
│   └── DutchAuction.sol      # 原生 DutchAuction(~78 行,含 abstract 层)
└── oz/
    └── DutchAuction.sol      # OZ 版(继承 raw)
test/
├── raw/DutchAuction.t.sol
└── oz/DutchAuction.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 8 个测试全部通过(raw 5 个 + oz 3 个)。

### 步骤 5:重点测试 —— 价格衰减(`test/raw/DutchAuction.t.sol`)

```solidity
function testAuctionMintAfterTime() public {
    vm.warp(block.timestamp + auction.AUCTION_TIME() + 1 minutes);   // 跳 11 分钟(超过 10 分钟)
    
    uint256 price = auction.getAuctionPrice();
    assertEq(price, 0.1 ether);                                       // 地板价
    
    uint256 quantity = 1;
    uint256 totalCost = price * quantity;

    vm.deal(address(this), totalCost);                                // 给测试合约充 ETH
    auction.auctionMint{value: totalCost}(quantity);
    assertEq(auction.totalSupply(), 1);
}
```

教学点:
- `vm.warp(now + 11 minutes)` 跳到拍卖结束后 1 分钟
- `vm.deal(address(this), totalCost)` Foundry cheatcode 给地址充 ETH(测试专用,主网做不到)
- `auctionMint{value: totalCost}(quantity)` 调拍卖,price = 0.1 ether(地板价)
- `vm.deal` 让测试合约(无 ETH 时也能 mint)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS:
  - **raw**: `testInitialState`、`testGetAuctionPrice`、`testAuctionMint`、`testAuctionMintAfterTime`、`testRevertMintBeforeStart`
  - **oz**: `testInitialState`、`testGetAuctionPrice`、`testAuctionMint`

## 8. 常见错误排查

### 错误 1:`auctionMint` 报 "Need to send more ETH"

- **常见原因**:`msg.value < getAuctionPrice() * quantity`
- **解决步骤**:`auctionMint{value: auction.getAuctionPrice() * quantity}(...)` 动态算
- **验证方式**:`testAuctionMint` 显式算 `price * quantity`

### 错误 2:`auctionMint` 报 "sale has not started yet"

- **常见原因**:`setAuctionStartTime` 推到未来了
- **解决步骤**:`vm.warp(auctionStartTime + 1)` 跳到 start 之后
- **验证方式**:`testRevertMintBeforeStart` 显式测了"未到 start mint 应 revert"

### 错误 3:想 mint 1 个却支付 1 ETH,亏了

- **常见原因**:没注意 `getAuctionPrice()` 实时变化(已衰减)
- **解决步骤**:
  ```solidity
  uint256 currentPrice = auction.getAuctionPrice();
  auction.auctionMint{value: currentPrice}(1);  // 用实时价,不是固定 1 ether
  ```
- **验证方式**:每次 mint 前先 `getAuctionPrice()`,看实际需要付多少

### 错误 4:找零退回失败

- **常见原因**:用 `.transfer` 给合约 owner,owner 是合约且 fallback 超过 2300 gas
- **解决步骤**:用 `payable(msg.sender).call{value: surplus}("")` + `require(success)`
- **验证方式**:本课找零用 `.transfer`,对 EOA 没问题;但 `withdrawMoney` 用 `.call` 兼容合约

## 9. 本节总结

- 荷兰拍卖 = **价格从高到低线性衰减**,先买先得,快速成交
- 5 个 constant 拍卖参数:START_PRICE / END_PRICE / TIME / DROP_INTERVAL / DROP_PER_STEP
- `getAuctionPrice()` 三段式:< start → 起始,进行中 → 衰减,>= start+TIME → 地板
- 找零机制:多付自动退,少付 revert
- ETH 累积 withdraw:owner 主动取,避免每次 mint 转账
- 与英式拍卖对比:荷兰式快(分钟级),英式慢(天数级,价往上走)
- 实战:NFT 发行 / Token IDO / ENS 域名拍卖
- 配合 `vm.deal` cheatcode 测试,Foundry 给地址充 ETH 无限制

## 10. 课后练习

### 练习 1
为 DutchAuction 加 **"分段"价格曲线**:
- 0~2 分钟:每分钟降 0.1 ETH(快速)
- 2~10 分钟:每分钟降 0.05 ETH(慢速)
- 修改 `getAuctionPrice` 用 `if/else if/else` 三段实现
- 加测试:0min 1.0 ETH,2min 0.8 ETH,5min 0.65 ETH,10min 0.1 ETH

### 练习 2
为 DutchAuction 加 **"白名单早鸟价"**:
- 加 `mapping(address => bool) public whitelist;`
- 白名单用户在拍卖前 5 分钟能以 0.05 ETH 固定价 mint
- 加测试:Alice 在白名单 + 0min,mint 1 个付 0.05 ETH(不是 1 ETH)

### 练习 3(进阶)
基于 raw 的 DutchAuction,实现 **"两阶段拍卖"**(荷兰 → 英式):
- 阶段 1(0~10min):荷兰式衰减
- 阶段 2(10min+):英式拍卖,价高者得,结束 24h 后无人出价则流拍
- 加测试:0min 用户以 1 ETH 拍走;10min 后用户出价 0.5 ETH,他人出价 0.7 ETH,拍卖结束时 0.7 ETH 得主胜出
- 提示:这是 Sotheby's 等传统拍卖行的链上版本
