# 第 40 课:NFTSwap —— P2P NFT 交易所

## 1. 本节目标

学完这节课,你能:
- 说清"为什么需要 NFTSwap,而不是 OpenSea 撮合"
- 自己手写一个最小可用的 NFTSwap(raw 实现)
- 理解 NFT 挂单的"两步走"——`approve` + `safeTransferFrom` 到 swap
- 区分 NFTSwap(本课,P2P 挂单)和 DutchAuction(39 课,价格衰减)
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 25 课:ERC721 非同质化代币(NFTSwap 操作 NFT)
- 第 14 课:Eth 与 fallback(`payable` + `msg.value` 接收 ETH)
- 第 17 课:合约调用(`safeTransferFrom` 是 NFT 转移的安全方式)

## 3. 先讲结论

**NFTSwap = P2P NFT 交易所:卖家挂单 + 锁定 NFT,买家付 ETH 拿走 NFT**。典型场景:
- **P2P NFT 二级市场**:CryptoPunks / BAYC 二级买卖(不通过 OpenSea)
- **NFT 拍卖结束后的清算**:拍卖流拍后让卖家自己挂单
- **小众 NFT 项目方市集**:项目方自建 swap,省 OpenSea 2.5% 手续费

**为什么不用 OpenSea 而要自己写?**
- OpenSea 抽 2.5% 手续费,自建 swap 0 手续费
- 卖家的 NFT 不离开项目方合约(OpenSea 会把 NFT 转走),减少信任成本
- **去中心化**:OpenSea 下架某 NFT 时,自建 swap 仍可交易
- 缺点:得自己写合约、自己前端、自己撮合

**NFTSwap 的四件套**:

| 方法 | 角色 | 作用 |
|------|------|------|
| `list(_nftAddr, _tokenId, _price)` | 卖家 | 挂单:NFT 转移到 swap,记录价格 |
| `revoke(_nftAddr, _tokenId)` | 卖家 | 撤单:NFT 退还给卖家 |
| `update(_nftAddr, _tokenId, _newPrice)` | 卖家 | 改价 |
| `purchase(_nftAddr, _tokenId) payable` | 买家 | 购买:付 ETH 拿 NFT,ETH 给卖家 |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/NFTSwap.sol` | ~104 行 |
| **oz** | `src/oz/NFTSwap.sol` | ~10 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 加 OZ 后缀(因 raw 已用 OZ `IERC721` / `IERC721Receiver`)。**生产用 OZ `ReentrancyGuard`**:防重入攻击(本课 `purchase` 中"先转 NFT 再付 ETH"实际是 Checks-Effects-Interactions,已安全)。

## 4. 合约设计

### 4.1 Order 结构体 + 双重 mapping

```solidity
struct Order {
    address owner;     // 卖家
    uint256 price;     // 价格(wei)
}

mapping(address => mapping(uint256 => Order)) public nftList;
// nftList[nftAddress][tokenId] → Order
```

要点:
- **双层 mapping** 是 NFTSwap 标配:`(NFT 地址, tokenId) → Order`,支持任意 NFT 系列
- `Order` 存 `owner` 而非 `seller`(后者可能在 NFT 转移后改名)

### 4.2 四个事件

```solidity
event List(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
event Purchase(address indexed buyer, address indexed nftAddr, uint256 indexed tokenId, uint256 price);
event Revoke(address indexed seller, address indexed nftAddr, uint256 indexed tokenId);
event Update(address indexed seller, address indexed nftAddr, uint256 indexed tokenId, uint256 newPrice);
```

教学点:**indexed 参数**用于链上过滤(按 seller 查询、按 tokenId 查询)。

### 4.3 业务流程

```
挂单(seller):
  1. nft.approve(swapAddr, tokenId)            ← 必须先授权
  2. swap.list(nftAddr, tokenId, 1 ether)      ← 内部把 NFT 转给 swap
       ↓
购买(buyer):
  3. swap.purchase{value: 1 ether}(nftAddr, tokenId)  ← 付 ETH
     → NFT 从 swap 转给 buyer
     → 1 ETH 转到 seller
     → (可选)多付的 ETH 退回 buyer
       ↓
撤单(seller):
  4. swap.revoke(nftAddr, tokenId)             ← NFT 退回 seller
```

### 4.4 关键设计选择

- **NFT 锁在 swap 里**:挂单时 NFT `safeTransferFrom` 到 swap,**卖家不能私自动** —— 这是"信用保证"
- **approve 检查**:`getApproved(tokenId) == address(this)`,确保卖家真的授权了
- **`safeTransferFrom`(而非 `transferFrom`)**:防止转给不支持 IERC721Receiver 的合约时 NFT 永久卡死
- **多付退款**:`if (msg.value > _order.price)`,自动退差额(防恶意多付)

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/NFTSwap.sol`

#### onERC721Received:接收 NFT 必须实现
```solidity
function onERC721Received(address, address, uint256, bytes calldata) external override returns (bytes4) {
    return IERC721Receiver.onERC721Received.selector;
}
```

要点:
- **每个要接收 ERC721 的合约**都必须实现这个回调
- 返回的 selector 必须等于 `bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"))`
- 这是 ERC721 标准的"接收方校验",防 NFT 误转给无法处理的合约

#### list:挂单
```solidity
function list(address _nftAddr, uint256 _tokenId, uint256 _price) public {
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.getApproved(_tokenId) == address(this), "Need Approval");
    require(_price > 0);

    Order storage _order = nftList[_nftAddr][_tokenId];
    _order.owner = msg.sender;
    _order.price = _price;

    _nft.safeTransferFrom(msg.sender, address(this), _tokenId);  // NFT 转移到 swap
    emit List(msg.sender, _nftAddr, _tokenId, _price);
}
```

要点:
- `getApproved` 检查卖家是否真的授权了
- `Order storage` 是 storage 引用,改 `_order.owner` 实际改 `nftList[_nftAddr][_tokenId].owner`
- 走 `safeTransferFrom`(非 transferFrom),触发 onERC721Received 回调

#### purchase:购买
```solidity
function purchase(address _nftAddr, uint256 _tokenId) public payable {
    Order storage _order = nftList[_nftAddr][_tokenId];
    require(_order.price > 0, "Invalid Price");
    require(msg.value >= _order.price, "Increase price");
    
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");
    
    _nft.safeTransferFrom(address(this), msg.sender, _tokenId);    // 1. NFT 转给买家
    (bool success, ) = payable(_order.owner).call{value: _order.price}("");  // 2. ETH 给卖家
    require(success, "Transfer failed.");
    
    if (msg.value > _order.price) {
        (success, ) = payable(msg.sender).call{value: msg.value - _order.price}("");  // 3. 找零
        require(success, "Refund failed.");
    }
    
    emit Purchase(msg.sender, _nftAddr, _tokenId, _order.price);
    delete nftList[_nftAddr][_tokenId];
}
```

要点:
- **先 NFT 后 ETH**(Checks-Effects-Interactions 变体):如果先 ETH 后 NFT,buyer 收到 ETH 但 NFT 转账失败,buyer 亏 ETH
- 找零**最后**给 buyer
- 全部成功才 `delete nftList[...]`(失败 revert 则状态保留)
- 实际生产中应加 `nonReentrant` modifier 防重入(虽然本流程已 CEI)

#### revoke:撤单
```solidity
function revoke(address _nftAddr, uint256 _tokenId) public {
    Order storage _order = nftList[_nftAddr][_tokenId];
    require(_order.owner == msg.sender, "Not Owner");
    
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");
    
    _nft.safeTransferFrom(address(this), msg.sender, _tokenId);
    delete nftList[_nftAddr][_tokenId];
    emit Revoke(msg.sender, _nftAddr, _tokenId);
}
```

要点:
- `require(_order.owner == msg.sender)` 防非卖家撤单
- `delete nftList` 清订单(返还 gas)

#### update:改价
```solidity
function update(address _nftAddr, uint256 _tokenId, uint256 _newPrice) public {
    require(_newPrice > 0, "Invalid Price");
    Order storage _order = nftList[_nftAddr][_tokenId];
    require(_order.owner == msg.sender, "Not Owner");
    
    IERC721 _nft = IERC721(_nftAddr);
    require(_nft.ownerOf(_tokenId) == address(this), "Invalid Order");
    
    _order.price = _newPrice;
    emit Update(msg.sender, _nftAddr, _tokenId, _newPrice);
}
```

要点:
- 只改价,NFT 不动(在 swap 里继续锁定)
- 不需要 `safeTransferFrom`

#### fallback:接 ETH
```solidity
fallback() external payable {}
```

要点:
- 接收直接给合约的 ETH(虽然本课业务不依赖直接打款)

### 5.2 oz 实现 —— `src/oz/NFTSwap.sol`

```solidity
import {NFTSwap as NFTSwapRaw} from "../../src/raw/NFTSwap.sol";

contract NFTSwapOZ is NFTSwapRaw {
    constructor() NFTSwapRaw() {}
}
```

要点:
- 业务完全一致
- 本项目 oz 版只是命名占位

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| IERC721 / IERC721Receiver | 用 OZ 的 | 继承 raw |
| 代码量 | ~104 行 | ~10 行 |
| 适用 | 学原理 | 命名风格占位 |

**生产应加 OZ `ReentrancyGuard`**:`purchase` 中"先转 NFT 后付 ETH"虽已是 CEI 模式,但加 nonReentrant 多一层保险。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/09_protocols/40_NFTSwap
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── ERC721.sol            # 25 课的 raw ERC721
│   └── NFTSwap.sol           # 原生 NFTSwap(~104 行)
└── oz/
    └── NFTSwap.sol           # OZ 版(继承 raw)
test/
├── raw/NFTSwap.t.sol         # 含 MockNFT + 5 个测试
└── oz/NFTSwap.t.sol          # 含 MockNFT + 4 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 9 个测试全部通过(raw 5 个 + oz 4 个)。

### 步骤 5:重点测试 —— 挂单 + 购买(`test/raw/NFTSwap.t.sol`)

```solidity
function testPurchase() public {
    vm.prank(seller);
    nft.approve(address(nftSwap), 0);                    // 1. seller 授权 swap

    vm.prank(seller);
    nftSwap.list(address(nft), 0, 1 ether);              // 2. seller 挂单

    vm.deal(buyer, 2 ether);                              // 3. 给 buyer 充 ETH
    vm.prank(buyer);
    nftSwap.purchase{value: 1 ether}(address(nft), 0);   // 4. buyer 付 1 ETH 买

    assertEq(nft.ownerOf(0), buyer);                      // 5. NFT 归 buyer
}
```

教学点:
- `vm.prank(seller)` 切换 `msg.sender` 为 seller(因为 NFT 在 seller 手里)
- `vm.deal(buyer, 2 ether)` Foundry cheatcode 给地址充 ETH
- 5 步走:approve → list → deal → purchase → assert

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 9 个测试全部 PASS:
  - **raw**: `testList`、`testRevoke`、`testUpdate`、`testPurchase`、`testPurchaseWithExtraRefund`
  - **oz**: `testList`、`testRevoke`、`testUpdate`、`testPurchase`

## 8. 常见错误排查

### 错误 1:`list` 报 "Need Approval"

- **常见原因**:seller 没先 `nft.approve(swapAddr, tokenId)`
- **解决步骤**:在 `nftSwap.list(...)` 前先 `nft.approve(address(nftSwap), tokenId)`
- **验证方式**:`testList` 中 `vm.prank(seller); nft.approve(...)` 是必要前置

### 错误 2:`purchase` 报 "Invalid Order"

- **常见原因**:NFT 不在 swap 手里(可能挂单后又撤了,或没挂单)
- **解决步骤**:先 `list` 再 `purchase`
- **验证方式**:`testPurchase` 中先 list 再 purchase

### 错误 3:`purchase` 报 "Increase price"

- **常见原因**:`msg.value < _order.price`
- **解决步骤**:`purchase{value: orderPrice}(...)`,看 nftList.price 决定
- **验证方式**:`testPurchase` 显式 `purchase{value: 1 ether}`

### 错误 4:多付 ETH 没收退款

- **常见原因**:买家用 2 ETH 付 1 ETH 单价,预期退 1 ETH
- **解决步骤**:合约自动找零;`testPurchaseWithExtraRefund` 验证 `buyerBalanceBefore - 1 ether`
- **验证方式**:用 `assertEq(buyer.balance, buyerBalanceBefore - 1 ether)` 验证

## 9. 本节总结

- NFTSwap = P2P NFT 交易所,**list → purchase** 是核心流程
- 双重 mapping:`nftList[nftAddr][tokenId] → Order`,支持任意 NFT 系列
- **挂单需要两步**:先 `nft.approve(swap, tokenId)`,再 `swap.list(...)`
- NFT **物理锁在 swap** 合约里,卖家不能私自动,buyer 才能拿
- `safeTransferFrom` 而非 `transferFrom`:接收方必须实现 onERC721Received
- `purchase` 走 CEI 模式:先 NFT 后 ETH,失败全部回滚
- 多付自动找零,防恶意多付卡住
- 与 DutchAuction(39 课)对比:NFTSwap 是 P2P 定价,荷兰是衰减定价
- 实战:BAYC / CryptoPunks 都有自己的 P2P 交换(防 OpenSea 下架)
- 生产应加 OZ `ReentrancyGuard` 增强安全

## 10. 课后练习

### 练习 1
为 NFTSwap 加 **批量挂单**:
- 暴露 `function listBatch(address _nftAddr, uint256[] _tokenIds, uint256 _priceEach) external`
- 校验授权 + 循环 `safeTransferFrom`
- 加测试:挂单 tokenId 0,1,2,验证 nftList 都有记录,3 个 NFT 都在 swap 里

### 练习 2
为 NFTSwap 加 **ERC20 价格(不用 ETH,用 DAI/USDC)**:
- 改 Order 加 `address paymentToken`(address(0) 表示 ETH)
- purchase 改用 `IERC20(paymentToken).transferFrom(buyer, seller, price)`
- 加测试:Alice 用 1000 DAI 买 NFT,验证 seller 收到 1000 DAI

### 练习 3(进阶)
基于 raw 的 NFTSwap,实现 **"限时降价"模式**:
- 加 `uint256 public discountUntil = block.timestamp + 7 days;`
- 前 7 天按 list price,7 天后自动 5 折
- 加测试:list 时 1 ether,vm.warp +8 days 后 purchase{value: 0.5 ether},验证成功
- 提示:这是 NFT 项目方"早期卖不动,降价清仓"的做法
