# 第 49 课:Random —— 链上随机数与 Chainlink VRF

## 1. 本节目标

学完这节课,你能:
- 说清"为什么链上 `keccak256(block.timestamp)` 是危险的伪随机"
- 自己手写一个链上伪随机数 SimpleRandom(raw 实现)
- 接入 Chainlink VRF v2,实现可验证随机数(oz 实现)
- 区分链上伪随机 vs 链下可验证随机的安全性差异
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 11 课:Keccak256(伪随机的种子核心)
- 第 17 课:合约调用(VRF 是跨合约回调模式)
- 第 35 课:Signature(VRF 内部用密码学签名验证)

## 3. 先讲结论

**链上随机数难题:以太坊是确定性 VM,任何"链上随机"本质都是公开的种子**。典型场景:
- **NFT 盲盒**:开盒时随机决定稀有度
- **链游战斗**:暴击判定、掉落
- **彩票/抽奖**:DAO 抽签、空投
- **协议清算**:随机选清算人

**两种方案对比**:

| 方案 | 实现 | 安全性 | 成本 | 适用 |
|------|------|--------|------|------|
| **链上伪随机** | `keccak256(block.timestamp, msg.sender, ...)` | ❌ 极不安全 | 0(只算 gas) | 教学/演示 |
| **Chainlink VRF** | 链下生成 + 链上密码学验证 | ✅ 可验证 | ~0.2 LINK | 生产 NFT/链游 |

**为什么链上伪随机不安全?**

```solidity
function badRandom() public view returns (uint256) {
    return uint256(keccak256(abi.encodePacked(
        block.timestamp, msg.sender, block.number
    )));
}
```

攻击向量:
1. **种子公开**:`block.timestamp` 矿工可调(±15s),`msg.sender` 攻击者控制,`block.number` 透明
2. **矿工操纵**:挖矿者可选择"不打包不利的交易",直到生成自己想要的 hash
3. **MEV 攻击**:用 flashloan + 链上模拟,只在"中奖时"才发交易
4. **同区块预测**:其他合约可在同一区块调你的合约,模拟出 random 值

**真实案例:Fomo3D 漏洞,攻击者用合约 + flashloan 反复模拟,锁定中奖时刻**。

**Chainlink VRF 解决方案**:
- 链下生成随机数 + 密码学证明
- 链上 VRFCoordinator 验证证明
- 没人能预测/操纵(包括 Chainlink 自己)
- 业界标准方案

**VRF 流程**:

```
1. 合约调 coordinator.requestRandomWords(keyHash, subId, ...)
   → 返回 requestId
   
2. Chainlink 预言机在链下:
   - 用 VRF 算法生成 random + proof
   - 用 LINK 付 gas,调 consumer.fulfillRandomWords(requestId, [random])
   
3. consumer 接收 random,业务逻辑使用
```

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/SimpleRandom.sol`(链上伪随机) | 65 行 |
| **oz** | `src/oz/SimpleRandom.sol` + `VRFConsumerBaseV2.sol`(Chainlink VRF) | 122 + 44 行 |

> 注:本项目 oz 版接入完整 Chainlink VRF v2 流程(测试用 mock coordinator)。**生产环境**直接用 Chainlink 官方 `VRFConsumerBaseV2` + 真实 coordinator 地址。

## 4. 合约设计

### 4.1 raw 实现:链上伪随机

```solidity
contract SimpleRandom {
    function getRandomOnchain() public view returns (uint256) {
        bytes32 randomBytes = keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            msg.sender,
            block.timestamp
        ));
        return uint256(randomBytes);
    }
    
    function getRandomInRange(uint256 min, uint256 max) public view returns (uint256) {
        uint256 random = getRandomOnchain();
        return min + (random % (max - min + 1));
    }
}
```

要点:
- 种子用 3 个链上变量:`blockhash(n-1)` + `msg.sender` + `block.timestamp`
- **看似安全,实则全部公开**,攻击者可预测
- 仅用于教学/演示,**绝不要用于生产**

### 4.2 oz 实现:Chainlink VRF v2

#### 状态

```solidity
struct RequestConfig {
    uint64 subId;                       // Chainlink 订阅 ID
    uint32 callbackGasLimit;            // 回调 gas 上限
    uint16 requestConfirmations;        // 区块确认数(防 reorg)
}

mapping(uint256 => address) public requestToRequester;   // requestId → 谁请求的
mapping(uint256 => uint256) public requestToRandom;      // requestId → 随机数结果
```

#### requestRandom(用户调)

```solidity
function requestRandom() external returns (uint256 requestId) {
    requestId = IVRFCoordinatorV2(vrfCoordinator).requestRandomWords(
        keyHash, cfg.subId, cfg.requestConfirmations, cfg.callbackGasLimit, 1
    );
    requestToRequester[requestId] = msg.sender;
    emit RandomRequested(requestId, msg.sender);
}
```

要点:
- 调 coordinator 拿 `requestId`,记录"谁请求的"
- **此时还没有随机数**,只是发了请求

#### fulfillRandomWords(Chainlink 回调)

```solidity
function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
    address requester = requestToRequester[requestId];
    require(requester != address(0), "Invalid request");
    
    requestToRandom[requestId] = randomWords[0];
    emit RandomFulfilled(requestId, requester, randomWords[0]);
}
```

要点:
- `internal override`:只有继承的 base 类(VRFConsumerBaseV2)能调
- base 类的 `rawFulfillRandomWords` 校验调用者是 vrfCoordinator
- `randomWords[0]`:Chainlink 一次可返回多个,本课只用 1 个

#### getRandomResult(用户查)

```solidity
function getRandomResult(uint256 requestId) external view returns (uint256) {
    uint256 random = requestToRandom[requestId];
    if (random == 0) revert RequestNotFulfilled(requestId);
    return random;
}
```

要点:
- 用户先调 requestRandom,等几个区块后调 getRandomResult 拿结果
- 未填充时 revert(避免用 0 当随机数)

### 4.3 三段流程

```
T0: 用户 → consumer.requestRandom() 
    → coordinator.requestRandomWords() → requestId = 1
   
T1: Chainlink 预言机(链下):
    - 用 VRF 算法生成 random + proof
    
T2: 预言机 → coordinator.fulfillRandomWords(requestId, [random], proof)
    → coordinator 验证 proof
    → coordinator → consumer.fulfillRandomWords(requestId, [random])
    → consumer 记录 random
    
T3: 用户 → consumer.getRandomResult(requestId) → 拿到 random
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/SimpleRandom.sol`(65 行)

4 个函数:
- `getRandomOnchain()`:基础伪随机
- `getRandomFromBlockhash(blockNumber)`:从指定区块算
- `getRandomInRange(min, max)`:限定范围
- `pickRandomElement(array)`:数组随机选

### 5.2 oz 实现 —— `src/oz/SimpleRandom.sol` + `VRFConsumerBaseV2.sol`

#### VRFConsumerBaseV2 抽象类(自包含版,44 行)

```solidity
abstract contract VRFConsumerBaseV2 {
    address public immutable vrfCoordinator;
    
    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }
    
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;
    
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomWords(requestId, randomWords);
    }
}
```

要点:
- `rawFulfillRandomWords` 是 coordinator 调的入口,校验调用者
- `fulfillRandomWords` 是 consumer 实现的虚函数

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 随机源 | 链上伪随机 | Chainlink VRF |
| 安全性 | ❌ 矿工可操纵 | ✅ 链下可验证 |
| 即时性 | 同步,立刻拿到 | 异步,等 2~10 个区块 |
| 成本 | 0(只 gas) | ~0.2 LINK |
| 代码量 | 65 行 | 122 + 44 = 166 行 |
| 适用 | 教学 / 演示 | 生产 |

**生产用 Chainlink VRF**:
- 用真实 coordinator 地址(每条链不同,见 docs.chain.link)
- 需要订阅 subscription,充值 LINK
- 测试链可用 mock coordinator

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/11_external_systems/49_Random
```

### 步骤 2:查看文件结构

```
src/
├── raw/SimpleRandom.sol          # 65 行,链上伪随机
└── oz/
    ├── SimpleRandom.sol          # 122 行,Chainlink VRF 消费者
    └── VRFConsumerBaseV2.sol     # 44 行,VRF 抽象基类
test/
├── raw/SimpleRandom.t.sol         # 8 个测试
└── oz/
    ├── SimpleRandom.t.sol          # 14 个测试
    └── VRFCoordinatorV2Mock.sol    # 测试用 mock coordinator
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 22 个测试全部通过(raw 8 个 + oz 14 个)。

### 步骤 5:重点测试 —— 完整 VRF 流程(`test/oz/SimpleRandom.t.sol`)

```solidity
function testFulfillRandomWords() public {
    vm.prank(alice);
    uint256 requestId = random.requestRandom();           // 1. alice 请求
    
    uint256 expectedSeed = 12345;
    coordinator.setSeed(requestId, expectedSeed);          // 2. mock 设置 seed
    coordinator.fulfillRandomWords(requestId, address(random));  // 3. mock 触发回调
    
    assertEq(random.requestToRandom(requestId), expectedSeed);   // 4. 验证 seed 被记录
}
```

教学点:
- mock coordinator 提供 `setSeed` 和 `fulfillRandomWords`,模拟 Chainlink 预言机
- 真实环境:发出 requestRandom 后,Chainlink 节点会在几个区块后自动回调

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 22 个测试全部 PASS:
  - **raw**: 8 个,覆盖 getRandomOnchain / getRandomInRange / getRandomFromBlockhash / pickRandomElement
  - **oz**: 14 个,覆盖部署/请求/回调/查询/Owner权限/异常

## 8. 常见错误排查

### 错误 1:链上伪随机被攻击者预测中奖

- **常见原因**:用 `keccak256(block.timestamp, ...)` 当真随机
- **解决步骤**:**绝对不要在生产用链上伪随机**,改用 Chainlink VRF
- **验证方式**:攻击合约可在同区块算出 random,只在中奖时才发交易

### 错误 2:VRF 回调失败 "out of gas"

- **常见原因**:`callbackGasLimit` 设置过低
- **解决步骤**:根据 fulfillRandomWords 内的逻辑设置合理 gas(默认 100000 起步)
- **验证方式**:回调内不要写复杂业务,只记录 random,业务逻辑放在用户主动 claim 函数

### 错误 3:requestRandom 报 "InvalidSubscription"

- **常见原因**:subscription 没充 LINK
- **解决步骤**:到 vrf.chain.link 创建 subscription + 充 LINK
- **验证方式**:本课用 mock,生产环境务必先充值

### 错误 4:fulfill 后 `getRandomResult` 返回 0

- **常见原因**:回调 random 恰好是 0(极低概率)被 `if (random == 0) revert` 误判
- **解决步骤**:用 mapping(requestId => bool) 单独记录"是否已 fulfill"
- **验证方式**:增加 `mapping(uint256 => bool) public requestFulfilled` 状态

## 9. 本节总结

- 以太坊是确定性 VM,链上"随机"本质都是种子公开的伪随机
- 链上伪随机:**仅教学用,绝不上生产**(矿工/MEV 可操纵)
- 生产方案:Chainlink VRF(链下生成 + 链上验证)
- VRF 流程:request → coordinator → 预言机回调 fulfillRandomWords
- 关键:`rawFulfillRandomWords` 校验只有 coordinator 能调
- 配合 NFT 盲盒(25 课):mint 时 request,fulfill 时分配稀有度
- 配合 DutchAuction(39 课):随机数决定中奖人
- 实战:Azuki / BAYC 等 NFT 项目都用 VRF 做盲盒

## 10. 课后练习

### 练习 1
基于 oz 的 SimpleRandomOZ,实现 **NFT 盲盒**:
- 用户调 `mintBlindBox()` → 内部 requestRandom + 记录 user
- fulfill 时,根据 randomWord % 100 决定稀有度(普通 80% / 稀有 15% / 史诗 5%)
- 加 ERC721 + tokenURI,稀有度对应不同图片
- 加测试:多用户 mint,稀有度分布符合预期

### 练习 2
为 oz 的 SimpleRandomOZ 加 **批量请求**:
- 加 `requestRandomBatch(uint32 numWords) external returns (uint256)` 一次请求 N 个随机数
- fulfill 时记录所有 numWords
- 加测试:请求 5 个随机数,fulfill 后能查到 5 个

### 练习 3(进阶)
基于 raw 的 SimpleRandom,实现 **commit-reveal 随机数**(无需 VRF):
- 用户 commit hash(secret + 区块号),等待 N 个区块
- 用户 reveal secret,合约验证 hash + 用 secret + blockhash 算 random
- 加测试:正常 commit + reveal 拿 random,reveal 错 secret revert
- 提示:这是 NFT 盲盒"无预言机"方案,但用户必须 reveal 否则随机数浪费
