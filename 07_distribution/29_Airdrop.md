# 第 29 课:Airdrop —— 批量空投合约

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 Airdrop 必须用合约批量发,而不是 N 笔单转"
- 自己手写一个支持 ERC20 和 ETH 双通道的空投合约(raw 实现)
- 用 OpenZeppelin 的 ERC20 类型搭一个 Airdrop(oz 实现)
- 理解 `transferFrom` + `approve` 在空投场景的标准用法
- 理解 ETH 批转中"失败列表"(`failTransferList`)的设计意图
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 24 课:ERC20 同质化代币(`approve` / `transferFrom` 是空投核心)
- 第 14 课:Eth 与 fallback(批转 ETH 用 `.call{value:}` 而非 `.transfer`)
- 第 8 课:数组、结构体与映射(`calldata` 数组节省 gas)

## 3. 先讲结论

**Airdrop = 项目方"一次性给上百个地址"派发代币**。典型场景:UNI 空投、ENS 空投、ARB 空投。

**为什么必须用合约批转**:
- 单笔 ERC20 transfer 大约 50k gas,200 笔 = 10M gas → **一笔交易塞不下**(主网 gas limit 30M)
- 不用合约,就得发 N 笔交易,每笔 21k 基础 gas + 50k 转账 gas → 总开销 N × 71k
- 批量合约一次性循环,只付一次 21k 基础 gas + N × ~30k → **省 30~40%**

业务流程:

```
项目方先 mint/transfer N 个 token 给自己
   ↓
项目方调 token.approve(airdrop, N)   ← 关键!给 airdrop 授权
   ↓
项目方调 airdrop.multiTransferToken(token, [a1,a2,..], [n1,n2,..])
   ↓
airdrop 内部循环 token.transferFrom(项目方, a_i, n_i)
```

**ETH 空投**走不同路径:`payable` + `msg.value` + `.call{value:}`。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/Airdrop.sol` | ~55 行 |
| **oz** | `src/oz/Airdrop.sol` | ~45 行 |

## 4. 合约设计

### 4.1 状态

```solidity
mapping(address => uint256) public failTransferList;  // ETH 转账失败的地址 → 失败金额
```

只有一个 `mapping`,记录 ETH 转账失败的金额(便于事后补救)。

### 4.2 三/四个外部接口

| 方法 | 输入 | 用途 |
|------|------|------|
| `multiTransferToken(token, addrs, amounts)` | ERC20 + 地址数组 + 金额数组 | ERC20 批量空投 |
| `multiTransferETH(addrs, amounts) payable` | 地址数组 + 金额数组(`{value: sum}`) | ETH 批量空投 |
| `withdrawFromFailList(_to)` | 取款目的地 | 失败地址自助取回(仅 raw 实现) |
| `getSum(arr)` | 数组 | 工具函数,算总额 |

### 4.3 ERC20 空投流程

```
项目方:                                airdrop 合约:
1. mint N 给自己
2. approve(airdrop, N)
3. multiTransferToken(token, addrs, amounts) -->
                                       4. require(addrs.length == amounts.length)
                                       5. require(allowance(项目方, this) >= sum(amounts))
                                       6. for i: token.transferFrom(项目方, addrs[i], amounts[i])
```

**关键**:`transferFrom` 的 `from` 是项目方,不是 airdrop 合约 —— airdrop 只是"代扣"。

### 4.4 ETH 空投流程

```
项目方调用 multiTransferETH{value: sum(amounts)}(addrs, amounts)
   ↓
合约 require msg.value == sum(amounts)
   ↓
循环 .call{value: amounts[i]}("") 给每个地址
   ↓
失败的不立即 revert,而是记录在 failTransferList(后续可取回)
```

## 5. 代码拆解

### 5.1 raw 实现 —— ERC20 批量 (`src/raw/Airdrop.sol`)

```solidity
function multiTransferToken(
    address _token,
    address[] calldata _addresses,
    uint256[] calldata _amounts
) external {
    require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
    IERC20 token = IERC20(_token);
    uint256 _amountSum = getSum(_amounts);
    require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");

    for (uint256 i; i < _addresses.length; i++) {
        token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
    }
}
```
要点:
- 入参用 `calldata`(只读,比 `memory` 省 gas)
- 提前 `require allowance >= sum`,**短路检查**,不必跑到中途 OOG
- 循环里 `transferFrom(msg.sender, ...)` —— `msg.sender` 是项目方

### 5.2 raw 实现 —— ETH 批量与失败补救

```solidity
function multiTransferETH(
    address payable[] calldata _addresses,
    uint256[] calldata _amounts
) public payable {
    require(_addresses.length == _amounts.length, "...");
    uint256 _amountSum = getSum(_amounts);
    require(msg.value == _amountSum, "Transfer amount error");

    for (uint256 i = 0; i < _addresses.length; i++) {
        (bool success,) = _addresses[i].call{value: _amounts[i]}("");
        if (!success) {
            failTransferList[_addresses[i]] = _amounts[i];  // 失败的记账,不 revert
        }
    }
}

function withdrawFromFailList(address _to) external {
    uint256 failAmount = failTransferList[msg.sender];
    require(failAmount > 0, "You are not in failed list");
    failTransferList[msg.sender] = 0;
    (bool success,) = _to.call{value: failAmount}("");
    require(success, "Fail withdraw");
}
```
教学要点:
- **失败不 revert** —— 否则一个坏地址毁掉整批空投
- 失败者自己来 `withdrawFromFailList(_to)`,可以指定不同的 `_to`(原地址收不到时换地址)
- `failTransferList[msg.sender] = 0` **在外部调用前**(防重入)

### 5.3 oz 实现 —— 强类型版 (`src/oz/Airdrop.sol`)

```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AirdropOZ {
    mapping(address => uint256) public failTransferList;

    function multiTransferToken(
        ERC20 token,                            // ← 直接传 ERC20 类型,不用运行时 cast
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        require(_addresses.length == _amounts.length, "...");
        uint256 _amountSum = getSum(_amounts);
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "...");
        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }
    // multiTransferETH / getSum 与 raw 完全一致
    // 注:oz 版未实现 withdrawFromFailList
}
```
要点:
- 第一参数从 `address _token` 变成 `ERC20 token` —— 编译期就保证类型
- 业务逻辑完全等价

### 5.4 对照看 —— raw vs oz

| 维度 | raw Airdrop | oz AirdropOZ |
|------|-------------|--------------|
| token 参数 | `address` + 运行时 cast | `ERC20` 类型 |
| `withdrawFromFailList` | ✅ 提供 | ❌ 缺失(失败的 ETH 锁死) |
| 代码量 | ~55 行 | ~45 行 |

**生产用 raw 那种 `withdrawFromFailList` 更负责任** —— 否则失败的 ETH 永久卡在合约里。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/07_distribution/29_Airdrop
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── IERC20.sol
│   ├── ERC20.sol             # 24 课带 mint 的 raw ERC20
│   └── Airdrop.sol           # 原生 Airdrop
└── oz/
    ├── ERC20Minter.sol       # 带 mint 的 OZ 薄壳
    └── Airdrop.sol           # OZ 版 AirdropOZ
test/
├── raw/Airdrop.t.sol
└── oz/Airdrop.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 push 主线 6 个测试全部通过(raw 4 个 + oz 2 个);全量 `forge test` 共 11 个(push 6 + pull 5)。

### 步骤 5:重点测试 —— ETH 批转(`test/raw/Airdrop.t.sol`)

```solidity
function testMultiTransferETH() public {
    address payable[] memory addresses = new address payable[](2);
    addresses[0] = user1;
    addresses[1] = user2;
    uint256[] memory amounts = new uint256[](2);
    amounts[0] = 1 ether;
    amounts[1] = 2 ether;

    airdrop.multiTransferETH{value: 3 ether}(addresses, amounts);
    assertEq(user1.balance, 1 ether);
    assertEq(user2.balance, 2 ether);
}
```
教学点:
- 测试合约用 `{value: 3 ether}` 附带 ETH —— Foundry 默认给测试合约充了 79 octillion ETH,够花
- `user1` / `user2` 必须是 `address payable`,因为要接收 ETH
- 收款方是 EOA 地址(`address(1)` / `address(2)`),不会 revert

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 全部 PASS:**push 主线 6 个 + pull 模式 5 个,共 11 个**:
  - **raw push**: `testMultiTransferToken`、`testMultiTransferTokenLengthMismatch`、`testMultiTransferETH`、`testGetSum`
  - **oz push**: `testMultiTransferToken`、`testMultiTransferETH`
  - **raw pull**: `test_Claim`、`test_ClaimInvalidProof`、`test_ClaimByNonWhitelist`、`test_ClaimTwice`、`test_AllFourClaim`

## 8. 常见错误排查

### 错误 1:`multiTransferToken` 报 "Need Approve ERC20 token"

- **常见原因**:项目方没先 `approve(airdrop, sum)`
- **解决步骤**:`token.approve(airdrop, sum)` 后再调 airdrop
- **验证方式**:`setUp` 里 `token.approve(address(airdrop), 10000)` 是标准动作

### 错误 2:`multiTransferETH` 报 "Transfer amount error"

- **常见原因**:`msg.value != sum(amounts)`,可能多发或少发了 ETH
- **解决步骤**:`{value: airdrop.getSum(amounts)}` 自动算好总额
- **验证方式**:`testMultiTransferETH` 中精确指定 `{value: 3 ether}` 等于两个 amount 之和

### 错误 3:某个地址是合约且 fallback 失败,整批空投崩了(raw 没崩,但 oz 类似实现可能崩)

- **常见原因**:用 `.transfer()` 或 `.send()` 触发了 gas 不足
- **解决步骤**:用 `.call{value:}("")`,且**失败时仅记账不 revert**(raw 已实现)
- **验证方式**:Mock 一个"故意 revert 的接收合约",验证 airdrop 整体仍成功,该地址进 `failTransferList`

### 错误 4:OZ 版的 ETH 转账失败者,ETH 锁死在合约里

- **常见原因**:OZ 版没实现 `withdrawFromFailList`
- **解决步骤**:补一个 withdrawFromFailList,与 raw 版对齐
- **验证方式**:补完后写 `testWithdrawFromFailList`,触发失败 → 自助取款 → 余额回正

## 9. 本节总结(push 模式)

- Airdrop 用循环 + 单次交易省 30~40% gas
- ERC20 空投走 **approve + transferFrom**(项目方授权 airdrop 代扣)
- ETH 空投走 **payable + .call{value:}**,失败的不 revert,记到 `failTransferList`
- 失败补救:暴露 `withdrawFromFailList`,让失败者自助取回
- 长度校验、`allowance` 短路检查、`msg.value == sum` 三大前置 require

## 10. 扩展:Merkle Tree claim 模式(pull)

> **MerkleTree 第 34 课会系统讲**,本节先按模板使用 —— 重点是看清"链下白名单 + claim 链上验证"的整体流程,不要纠结 Merkle 树怎么生成。

### 10.1 为什么 push 模式不够

push 模式 `multiTransferToken(addrs, amounts)` 把白名单直接放在 calldata 里一次性循环。**白名单超过几千人时**:

```
addrs.length = 100_000
addresses(20 字节) + amounts(32 字节) ≈ 52 字节/项
   × 100_000 = 5.2 MB calldata
   → 单笔交易 gas 上限直接爆掉(主网 block gas limit ~30M)
```

更糟糕的是:**没收到的人要等下一轮**,**多笔分发 = 多笔失败处理**。

### 10.2 pull 模式核心思路

```
链下:                          链上:
项目方构造白名单                   部署 MerkleAirdrop(token, root)
   ↓                            把所有 token 一次性 transfer 给 airdrop
   leaf = keccak256(addr, amt)   
   构造成 Merkle Tree            用户自己来 claim
   ↓                            claim(amount, proof):
用户得到 proof                   1. claimed[user]? revert
(merkle-tree.js 生成)            2. leaf = keccak256(user, amount)
                                  3. MerkleProof.verify(proof, root, leaf)
                                  4. 验证通过:claimed[user] = true + transfer
```

**优势**:
- **链上数据极小**:只需存 `bytes32 root`(32 字节),白名单在链下
- **失败者自己付 gas**:项目方只付一次 deposit
- **白名单可极大**:10 万人也只发一笔 deposit,每笔 claim 独立
- **无需 failList**:用户随时来领,领不到就 re-claim(没空投失败这回事)

### 10.3 业务流程

```
1. 项目方构造 Merkle Tree(链下,JS / Python 都行)
2. 项目方部署 MerkleAirdrop(token, root),把全部 token 转给合约
3. 项目方公布 root + 每个白名单用户的 proof(可放 IPFS / 官网)
4. 用户用 front-end 拿到自己的 proof
5. 用户调 airdrop.claim(amount, proof)
6. 合约验 proof → 转账
```

### 10.4 关键代码 —— `src/raw/MerkleAirdrop.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "./IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleAirdrop {
    IERC20 public immutable token;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public claimed;

    event Claimed(address indexed claimant, uint256 amount);

    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();

    constructor(IERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();

        claimed[msg.sender] = true;
        emit Claimed(msg.sender, amount);

        bool ok = token.transfer(msg.sender, amount);
        if (!ok) revert TransferFailed();
    }
}
```

**教学点**:
- `merkleRoot` 用 `immutable` 存(部署后永不变 —— Merkle 模式核心安全)
- `claimed` mapping 防双花(同一用户第二次 claim revert)
- leaf 公式 `keccak256(abi.encodePacked(user, amount))` —— 一定要和链下生成器一致
- 用 `MerkleProof.verify` 而不是自己实现 hash 拼接
- `immutable` 让 `merkleRoot` 不占 storage slot,直接嵌 bytecode,省 gas

### 10.5 leaf 字段顺序 —— 容易踩的坑

`abi.encodePacked(user, amount)` 的字节序必须与链下生成器一致:

```js
// 链下 merkle-tree.js(对应)
const leaf = ethers.solidityPackedKeccak256(
    ["address", "uint256"],
    [user, amount]
);
```

如果链上是 `abi.encodePacked(user, amount)`,链下用 `solidityPackedKeccak256(["address", "uint256"], ...)` —— 两者一致。**字段顺序或类型不一致,proof 永远 verify 不过**。

### 10.6 实操步骤

```bash
cd 0xF1/foundry_projects/07_distribution/29_Airdrop

# 项目结构(Merkle 部分新增)
src/raw/MerkleAirdrop.sol          # 上面这份合约
test/raw/MerkleAirdrop.t.sol       # 5 个测试
```

```bash
forge build
forge test --match-path "test/raw/MerkleAirdrop.t.sol" -vv
```

预期 5 个测试全部通过:
- `test_Claim` —— 合法 claim,余额正确 + claimed 标记
- `test_ClaimInvalidProof` —— 错 proof revert
- `test_ClaimByNonWhitelist` —— 非白名单用户 revert
- `test_ClaimTwice` —— 二次 claim revert
- `test_AllFourClaim` —— 4 个白名单都领完,合约余额清零

### 10.7 重点测试 —— 4 叶子 Merkle Tree 构造

```solidity
function setUp() public {
    token = new ERC20("Test", "TST");
    token.mint(1000e18);

    // 4 叶子 → 2 中间节点 → root(每个内部节点 = keccak256(小||大))
    bytes32 l0 = keccak256(abi.encodePacked(alice, ALICE_AMOUNT));
    bytes32 l1 = keccak256(abi.encodePacked(bob,   BOB_AMOUNT));
    bytes32 l2 = keccak256(abi.encodePacked(carol, CAROL_AMOUNT));
    bytes32 l3 = keccak256(abi.encodePacked(dave,  DAVE_AMOUNT));

    bytes32 n01 = keccak256(abi.encodePacked(l0 < l1 ? l0 : l1, l0 < l1 ? l1 : l0));
    bytes32 n23 = keccak256(abi.encodePacked(l2 < l3 ? l2 : l3, l2 < l3 ? l3 : l2));
    root = keccak256(abi.encodePacked(n01 < n23 ? n01 : n23, n01 < n23 ? n23 : n01));

    airdrop = new MerkleAirdrop(token, root);
    token.transfer(address(airdrop), 1000e18);

    aliceProof = [l1, n23];   // alice 的兄弟节点 + 上一层
    bobProof   = [l0, n23];
    carolProof = [l3, n01];
    daveProof  = [l2, n01];
}
```

教学点:
- **sorted pair**(小在前,大在后)防止 OZ 警告中提到的 64 字节前缀碰撞攻击
- proof 长度 = O(log₂(白名单数)):4 叶子 = 2 层 = 2 个兄弟
- 4 个白名单用户都是 EOA(`alice = 0xA11CE`、`bob = 0xB0B` 等),用 `vm.prank(alice)` 切到该地址调 `claim`;真实场景 leaf 字段换成真实用户地址即可

### 10.8 push vs pull 对比

| 维度 | push 模式(本节正文) | pull 模式(Merkle) |
|------|---------------------|---------------------|
| 白名单大小 | 几千人上限 | 几十万人 OK |
| 项目方付 gas | 一次循环(可能 30M+) | 一次 deposit + 部署 |
| 用户付 gas | 0 | 自己付 claim gas |
| 失败处理 | failList + 提款 | 不存在"失败" |
| 链上数据 | 完整白名单 calldata | 只存 `bytes32 root` |
| 中继依赖 | 无 | 无(纯合约) |
| 适用 | 小型空投(<1 万人) | 大型空投(>1 万人) |

### 10.9 实战参考

- **Uniswap**:UNI 空投采用 Merkle pull 模式
- **Optimism**:OP 空投也是 Merkle pull
- **Arbitrum**:ARB 空投同样模式
- **ENS**:ENS 空投
- **Airdrop 工具**:`@openzeppelin/merkle-tree`(JS 库,链下生成 root + proof)

> 注:**Merkle 树本身怎么生成的**、**双 hash 防碰撞**、**OpenZeppelin merkle-tree JS 库用法**留到第 34 课系统讲,本节先用现成模式。

## 11. 课后练习

### 练习 1
为 OZ 版 `AirdropOZ` **补全 `withdrawFromFailList`**:
- 直接照抄 raw 版逻辑
- 加测试 `testWithdrawFromFailList`:用一个"必然 revert 的接收合约"作为 user1,空投失败后该合约自助调 `withdrawFromFailList`,验证能取回

### 练习 2
为 raw 版 Airdrop 加 **事件**:
- `event MultiTransferTokenDone(address indexed token, address indexed sender, uint256 count, uint256 totalAmount);`
- `event MultiTransferETHDone(address indexed sender, uint256 count, uint256 totalAmount, uint256 failCount);`
- 加测试用 `vm.expectEmit` 校验事件触发

### 练习 3(进阶)
为 MerkleAirdrop 加 **批量 claim**:
- 暴露 `function claimMulti(Claim[] calldata claims) external`
- `Claim { uint256 amount; bytes32[] proof; }`
- 一次交易领多次(但只能一个 msg.sender 一次,本练习改成"管理员帮用户代发"模式)
- 管理员一次性提交多个用户的 claim,降低用户门槛(用户不需自己付 gas)
- 加测试:管理员调 claimMulti 后 4 个白名单用户都到账
