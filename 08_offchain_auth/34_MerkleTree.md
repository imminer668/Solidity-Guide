# 第 34 课:MerkleTree —— Merkle 树白名单铸造

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 NFT 白名单常用 Merkle 树,而不是 `mapping(address => bool)`"
- 自己手写一个 `MerkleProof` 库 + `MerkleTree` NFT 合约(raw 实现)
- 用 OpenZeppelin 的 `MerkleProof` 库快速搭一个白名单 NFT(oz 实现)
- 理解 `_hashPair` 排序防 second-preimage 攻击的设计
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 25 课:ERC721 非同质化代币(MerkleTree 继承 ERC721,铸造 NFT)
- 第 11 课:Keccak256 哈希(`keccak256(abi.encodePacked(...))` 是构建 leaf/parent 的关键)
- 第 9 课:Mapping(MerkleTree 用 `mintedAddress` 防双花)

## 3. 先讲结论

**MerkleTree 白名单铸造 = 把"所有白名单地址"哈希成一棵二叉树,部署时只把根(root)上链,用户提供 proof 自证在白名单中**。典型场景:
- **Uniswap 空投**:25 万地址,只把 ~32 字节 root 写上链,用户提交 proof 领取
- **NFT 白名单 mint**:1 万个预售地址,gas 比 storage mapping 便宜
- **Layer2 状态根**:Rollup 把整批交易哈希成 root 提交 L1

**为什么用 Merkle 树而不是 `mapping(address => bool)`?**
- 1 万地址白名单:每个 mapping slot 32 字节,1 万个 = **320k 字节**,部署就要付 320k gas × 16 = 5M+ gas
- Merkle 树只存 root:**32 字节**,部署成本可忽略
- 验证单个 leaf 只需 O(log N) 兄弟节点,1 万地址只要 14 个 proof 元素,每次 mint ~50k gas
- 缺点:用户必须前端算 proof、提交 proof,UX 比 mapping 复杂

**Merkle 验证原理**:

```
        ROOT
       /    \
     H01     H23
    /  \    /  \
   H0  H1  H2  H3
   |   |   |   |
   L0  L1  L2  L3   ← 白名单地址(leaf)

要证明 L2 在树中:
- L2 → H2 = hash(L2)                ← leaf 计算
- 给出 H3 兄弟节点
- H23 = hash(H2, H3)                ← 一层
- 给出 H01 兄弟节点
- ROOT = hash(H01, H23)             ← 顶层
- 比对 ROOT == 合约存的 root
```

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/MerkleTree.sol` + `MerkleProof.sol` + `ERC721.sol` | ~33 + 26 + (~50) 行 |
| **oz** | `src/oz/MerkleTree.sol` | ~32 行 |

> 注:oz 版继承 OZ `ERC721` 并使用 OZ `MerkleProof` 库,业务逻辑与 raw 完全一致。

## 4. 合约设计

### 4.1 MerkleProof 库的核心三函数

```solidity
function verify(bytes32[] memory proof, bytes32 root, bytes32 leaf) 
    internal pure returns (bool)
{ return processProof(proof, leaf) == root; }

function processProof(bytes32[] memory proof, bytes32 leaf) 
    internal pure returns (bytes32)
{
    bytes32 computedHash = leaf;
    for (uint256 i = 0; i < proof.length; i++) {
        computedHash = _hashPair(computedHash, proof[i]);
    }
    return computedHash;
}

function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
}
```

要点:
- `verify` 是入口:算出来的根 == 给的根?
- `processProof` 模拟"沿兄弟节点向上爬":leaf 与 proof[i] 一层层 hash
- **`_hashPair` 必须排序**:`a < b ? hash(a,b) : hash(b,a)` —— 防 second-preimage 攻击(否则 `hash(L2, H3) != hash(H3, L2)`,攻击者可偷换 leaf)

### 4.2 MerkleTree 合约状态

```solidity
bytes32 public immutable root;            // Merkle 树根,部署时一次性写入
mapping(address => bool) public mintedAddress;  // 已 mint 状态
```

`root` 是 `immutable`:部署后终身不变。

### 4.3 mint 流程

```
用户前端:
  1. 拿到自己的 (address, tokenId) 和 proof
  2. 调用 merkleTree.mint(account, tokenId, proof)
       ↓
合约:
  1. 计算 _leaf(account) = keccak256(abi.encodePacked(account))
  2. 调 MerkleProof.verify(proof, root, _leaf)
  3. require(verify == true, "Invalid merkle proof")
  4. require(!mintedAddress[account], "Already minted!")
  5. mintedAddress[account] = true
  6. _mint(account, tokenId)
```

## 5. 代码拆解

### 5.1 raw 实现 —— MerkleProof 库 (`src/raw/MerkleProof.sol`)

```solidity
function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
    return a < b ? keccak256(abi.encodePacked(a, b)) : keccak256(abi.encodePacked(b, a));
}
```

教学点:**排序是关键**。如果写 `keccak256(abi.encodePacked(a, b))`(无排序),攻击者可以这样:
- 真实 leaf `L2` + 真实 proof `H3`,算出 `hash(L2, H3) = H23`
- 伪造 leaf `L2'`(不在白名单),伪造 proof `H3'`,只要 `hash(L2', H3')` 也等于某个 H23,就能冒充
- 加排序后:`hash(L2, H3) == hash(H3, L2)`,但 `hash(L2, H3) != hash(L2, H3')`,攻击失效

### 5.2 raw 实现 —— MerkleTree 主合约 (`src/raw/MerkleTree.sol`)

#### _leaf:地址转 leaf
```solidity
function _leaf(address account) internal pure returns (bytes32) {
    return keccak256(abi.encodePacked(account));
}
```

要点:
- `abi.encodePacked` 把 address 压成 20 字节,然后 keccak256
- **实际项目**会再加 amount / tokenId 等信息:`keccak256(abi.encodePacked(account, amount))`

#### mint:验证 + 铸造
```solidity
function mint(address account, uint256 tokenId, bytes32[] calldata proof) external {
    require(_verify(_leaf(account), proof), "Invalid merkle proof");
    require(!mintedAddress[account], "Already minted!");

    mintedAddress[account] = true;
    _mint(account, tokenId);
}
```

要点:
- 入参 `proof` 用 `calldata`(只读,比 memory 省 gas)
- **三步走**:验 proof(合法性) → 查 minted(防双花) → 铸 NFT
- `_verify` 内部调 `MerkleProof.verify(proof, root, leaf)`

### 5.3 oz 实现 —— OZ MerkleProof + OZ ERC721 (`src/oz/MerkleTree.sol`)

```solidity
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract MerkleTreeOZ is ERC721 {
    bytes32 public immutable root;
    mapping(address => bool) public mintedAddress;

    constructor(bytes32 merkleroot, string memory name, string memory symbol) 
        ERC721(name, symbol) 
    {
        root = merkleroot;
    }

    function mint(address account, uint256 tokenId, bytes32[] calldata proof) external {
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        require(!mintedAddress[account], "Already minted!");
        mintedAddress[account] = true;
        _mint(account, tokenId);
    }
    
    // _leaf / _verify 与 raw 一致
}
```

要点:
- 业务逻辑与 raw 完全一致
- OZ `MerkleProof` 库自带排序和标准验证,生产用这个
- OZ `ERC721` 自带元数据、approve、safeTransferFrom 等全套接口

### 5.4 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| MerkleProof 库 | 自写(`src/raw/MerkleProof.sol`,~26 行) | 引入 OZ `MerkleProof` |
| ERC721 | 自写(继承第 25 课 raw ERC721) | 引入 OZ `ERC721` |
| 业务逻辑 | 完全一致 | 完全一致 |
| 代码量 | MerkleTree 主合约 ~33 行 | ~32 行 |
| 适用 | 学原理 | 生产代码 |

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/08_offchain_auth/34_MerkleTree
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── ERC721.sol            # 25 课的 raw ERC721
│   ├── MerkleProof.sol       # 自写 MerkleProof 库(~26 行)
│   └── MerkleTree.sol        # 原生 MerkleTree NFT(~33 行)
└── oz/
    └── MerkleTree.sol        # OZ 版 MerkleTreeOZ(~32 行)
test/
├── raw/MerkleTree.t.sol
└── oz/MerkleTree.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 6 个测试全部通过(raw 4 个 + oz 2 个)。

### 步骤 5:重点测试 —— proof 验证(`test/raw/MerkleTree.t.sol`)

```solidity
bytes32 public root = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba8c097;  // ← 教学预设 root
address public user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

function setUp() public {
    merkleTree = new MerkleTree(root);
}

function testMintWithValidProof() public {
    bytes32[] memory proof = new bytes32[](2);
    proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
    proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;

    merkleTree.mint(user1, 0, proof);
    assertEq(merkleTree.ownerOf(0), user1);
}
```

教学点:
- root / proof / leaf 是教程预设值,真实项目前端用 `@openzeppelin/merkle-tree` 库生成
- 提交 `(user1, 0, proof)` → 合约内部算 `keccak256(abi.encodePacked(user1))` 作 leaf,沿 proof 爬到根,与 `root` 比对
- 一致 → mint 成功,`ownerOf(0) == user1`

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 6 个测试全部 PASS:
  - **raw**: `testMintWithValidProof`、`testMintWithInvalidProof`、`testCannotMintTwice`、`testMerkleProofVerify`
  - **oz**: `testMintWithValidProof`、`testMintWithInvalidProof`

## 8. 常见错误排查

### 错误 1:`mint` 报 "Invalid merkle proof"

- **常见原因**:`keccak256(abi.encodePacked(account))` 算出的 leaf 与 proof 爬出来的根不匹配
- **解决步骤**:
  1. 确认 leaf 计算方式与生成 root 时一致(都是 `keccak256(abi.encodePacked(account))` 还是 `keccak256(abi.encodePacked(account, amount))`)
  2. 确认 proof 数组顺序对(从 leaf 往根)
  3. 重新用 `@openzeppelin/merkle-tree` 算 root 和 proof
- **验证方式**:用教程预设的 root / proof 跑通后,再换自己的数据

### 错误 2:同一地址想 mint 两个不同 tokenId 失败

- **常见原因**:`mintedAddress[account] = true` 标记,防"一个白名单地址薅多个"
- **解决步骤**:本课设计就是"白名单地址只能 mint 一次"。要"一次 mint 多个"就重写:
  ```solidity
  // 改 mintedAddress 为 mapping(address => uint256) public mintedCount;
  // require(mintedCount[account] < maxMintPerAddress);
  ```
- **验证方式**:`testCannotMintTwice` 显式测了"二次 mint 必须 revert"

### 错误 3:OZ 版编译失败:找不到 MerkleProof

- **常见原因**:remappings 没配,`@openzeppelin/contracts/...` 解析不到
- **解决步骤**:`remappings.txt` 加 `forge-std/=lib/forge-std/src/` 和 `@openzeppelin/contracts/=lib/openzeppelin-contracts/contracts/`
- **验证方式**:`forge build` 应能找到 `MerkleProof.sol`

### 错误 4:从 raw 切换到 oz,行为不一致

- **常见原因**:OZ MerkleProof 库是 `calldata` 版本(节省 gas),但 leaf 计算方式严格一致才行
- **解决步骤**:OZ `MerkleProof.verify(proof, root, leaf)` 与 raw 完全等价
- **验证方式**:同一份 proof,raw 和 oz 行为应完全一致

## 9. 本节总结

- Merkle 树白名单 = **用 O(log N) 的 proof 代替 O(N) 的 storage**,gas 大幅下降
- 部署时只存 **32 字节 root**,用户提交 proof 验证
- `_hashPair` 必须排序,防 second-preimage 攻击
- 三步走 mint:**验 proof → 查 minted → 铸 NFT**
- 真实项目用 `@openzeppelin/merkle-tree` JS 库生成 root 和 proof
- 实战场景:Uniswap/ENS 空投、NFT 白名单、Layer2 状态根
- 生产用 OZ `MerkleProof` 库(已审计、可信)

## 10. 课后练习

### 练习 1
为 MerkleTree 加上 **"每地址可 mint 多次"** 模式:
- 把 `mintedAddress` 改为 `mapping(address => uint256) public mintedCount;`
- 加 `uint256 public maxMintPerAddress = 3;`
- 校验 `mintedCount[account] < maxMintPerAddress`
- 加测试:同一地址连续 mint 3 次都成功,第 4 次 revert

### 练习 2
为 MerkleTree 加 **"按 tokenId 段分配"**:
- leaf 计算改为 `keccak256(abi.encodePacked(account, startTokenId, endTokenId))`
- mint 时 tokenId 在 `[startTokenId, endTokenId]` 范围内任选
- 加测试:Alice 在段 [0, 100] 内 mint 50 号,ownerOf(50) == Alice

### 练习 3(进阶)
为 MerkleTree 加 **"可多阶段更新 root"**:
- 部署时 root 设为初始 root
- 加 `function updateRoot(bytes32 newRoot) external onlyOwner`
- 加事件 `event RootUpdated(bytes32 oldRoot, bytes32 newRoot)`
- 加测试:owner 调 updateRoot,queuedTransactions 不变,新 root 下老 proof 失败
- 提示:这是很多 NFT 项目"分阶段开白"的做法
