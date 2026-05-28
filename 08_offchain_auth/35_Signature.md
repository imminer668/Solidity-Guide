# 第 35 课:Signature —— ECDSA 签名白名单铸造

## 1. 本节目标

学完这节课,你能:
- 说清"为什么用 ECDSA 签名做白名单,比 Merkle 树简单又比 mapping 节省 gas"
- 自己手写一个 `ECDSA` 库 + `SignatureNFT` 合约(raw 实现)
- 理解 `"\x19Ethereum Signed Message:\n32"` 前缀的防重放意义
- 用 Foundry `vm.sign` cheatcode 在测试中模拟签名
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 25 课:ERC721 非同质化代币(本课铸造 NFT)
- 第 34 课:MerkleTree(本课是另一种白名单模式,优缺点对比)
- 第 11 课:Keccak256 哈希(`ecrecover` 内部用 keccak256)
- 第 10 课:Address 与地址运算(`ecrecover` 返回 signer 地址)

## 3. 先讲结论

**Signature 白名单铸造 = 项目方链下对 `(user, tokenId)` 签名,用户链上提交签名,合约用 `ecrecover` 验证 signer**。典型场景:
- **NFT 优先购白名单**:项目方给预售用户发签名,用户 mint 时带签名
- **代币空投凭证**:项目方对地址签名,用户凭签名领空投
- **Gasless 授权**:用户签一笔"授权卖币"消息,项目方代为上链(后两课展开)

**与 Merkle 树(34 课)对比**:

| 维度 | Merkle 树 | ECDSA 签名(本课) |
|------|----------|------------------|
| 项目方成本 | 链下算 1 个 root | 链下签 N 个签名 |
| 链上成本 | 部署 32 字节 root | 部署 1 个 signer 地址 |
| 用户成本 | 提交 O(log N) 个 proof | 提交 1 个签名(65 字节) |
| 灵活性 | 一次发布,难增删用户 | 可动态签新用户 |
| 链下可信 | 任何人可算 root | 私钥泄露即丢 |
| 实战 | Uniswap/ENS 大规模空投 | NFT 白名单/优先购 |

**核心机制**:`ecrecover(hash, v, r, s) → address` —— EVM 原生函数,从签名恢复出 signer 地址。

**`"\x19Ethereum Signed Message:\n32"` 前缀**:这是以太坊签名标准(eth_sign / personal_sign)。如果不用这个前缀,签名可以被其他合约/应用**重放**(同一份签名在不同合约不同函数下都有效)。

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/SignatureNFT.sol` + `ECDSA.sol` | ~35 + 27 行 |
| **oz** | `src/oz/SignatureNFT.sol` | ~46 行 |

> 注:本项目 oz 版**没有引入 OZ 的 `ECDSA.sol` 库**,只是继承了 OZ 的 `ERC721` + 把 ecrecover 内联(与 raw 等价但更长)。**生产环境请用 OZ `ECDSA.recover`**:它内置了 malleability 检查,防 `s` 值翻转到伪造签名。

## 4. 合约设计

### 4.1 状态

```solidity
address public immutable signer;        // 项目方公钥(部署时锁定)
mapping(address => bool) public mintedAddress;  // 已 mint 状态
```

### 4.2 mint 流程

```
链下(项目方):
  1. msgHash = keccak256(abi.encodePacked(user, tokenId))
  2. ethHash = keccak256("\x19Ethereum Signed Message:\n32" ++ msgHash)
  3. 用项目方私钥对 ethHash 签名,得 (v, r, s)
  4. 把 (v, r, s) 发给 user
       ↓
链上(user):
  5. 调 signatureNFT.mint(account, tokenId, abi.encodePacked(r, s, v))
       ↓
合约:
  6. msgHash = keccak256(abi.encodePacked(account, tokenId))   ← 必须与链下完全一致
  7. ethHash = keccak256("\x19Ethereum Signed Message:\n32" ++ msgHash)
  8. recovered = ecrecover(ethHash, v, r, s)
  9. require(recovered == signer, "Invalid signature")
  10. require(!mintedAddress[account], "Already minted!")
  11. mintedAddress[account] = true
  12. _mint(account, tokenId)
```

### 4.3 三段式 hash 的设计意图

```
链下 hash        链上 hash
  ↓                ↓
(原始参数) →  msgHash  → ethHash  → sign(ethHash) →  (v,r,s)
              ^^^^^^^^^
              必须一致 —— 这是链上链下"协议契约"
```

任何一段不一致,签名都验证失败。

## 5. 代码拆解

### 5.1 raw 实现 —— ECDSA 库 (`src/raw/ECDSA.sol`)

#### toEthSignedMessageHash:加以太坊签名前缀
```solidity
function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
    return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
}
```

要点:
- `"\x19Ethereum Signed Message:\n32"` = 26 字节字符串
- 这是 EIP-191 标准前缀,`personal_sign` / `eth_sign` 都用这个
- 加上后:同一份 msgHash 在不同合约不同函数下 hash 不同,**防跨合约重放**

#### recoverSigner:从签名恢复地址
```solidity
function recoverSigner(bytes32 msgHash, bytes memory signature) internal pure returns (address) {
    require(signature.length == 65, "invalid signature length");
    bytes32 r;
    bytes32 s;
    uint8 v;
    assembly {
        r := mload(add(signature, 0x20))    // 前 32 字节 = r
        s := mload(add(signature, 0x40))    // 中 32 字节 = s
        v := byte(0, mload(add(signature, 0x60)))  // 末 1 字节 = v
    }
    return ecrecover(msgHash, v, r, s);
}
```

要点:
- 签名 = `abi.encodePacked(r, s, v)`,**总长 65 字节**
- `assembly` 直接读 memory,比 Solidity 解析更省 gas
- `ecrecover` 是 EVM 预编译(地址 0x01),gas 固定 3000

#### verify:恢复并比对
```solidity
function verify(bytes32 msgHash, bytes memory signature, address signer) internal pure returns (bool) {
    return recoverSigner(msgHash, signature) == signer;
}
```

要点:
- `pure` 函数不读链上状态
- 用 `==` 直接比对,成功返回 true,失败返回 false

### 5.2 raw 实现 —— SignatureNFT 主合约 (`src/raw/SignatureNFT.sol`)

```solidity
function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
    bytes32 _msgHash = getMessageHash(_account, _tokenId);
    bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash);
    require(verify(_ethSignedMessageHash, _signature), "Invalid signature");
    require(!mintedAddress[_account], "Already minted!");

    mintedAddress[_account] = true;
    _mint(_account, _tokenId);
}
```

要点:
- 入参顺序 `(_account, _tokenId, _signature)` —— **链上链下顺序必须一致**,否则 hash 不同
- `_signature` 用 `memory`(因为要传给 ECDSA 库)
- 链上算 msgHash 和链下算 msgHash 的 `abi.encodePacked` 参数必须**完全一致**

### 5.3 oz 实现 —— `src/oz/SignatureNFT.sol`

```solidity
contract SignatureNFTOZ is ERC721 {
    // ... 状态与 raw 一致
    
    function verify(bytes32 msgHash, bytes memory signature) public view returns (bool) {
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly { ... }  // 同样的内联 assembly
        return ecrecover(msgHash, v, r, s) == signer;
    }
}
```

要点:
- 业务逻辑与 raw 完全一致
- **没引入 OZ `ECDSA.sol` 库** —— 仍然内联 ecrecover
- 教学价值:展示了"oz 版不一定都用 OZ 库",按需引入

**生产用 OZ `ECDSA.recover`**:
```solidity
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
address signer = ECDSA.recover(hash, signature);  // 内置 s 值 malleability 检查
```

### 5.4 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| ECDSA 库 | 自写(`src/raw/ECDSA.sol`,~27 行) | 内联在合约里(占 ~15 行) |
| ERC721 | 自写(继承 25 课) | 引入 OZ `ERC721` |
| ecrecover | 库函数 | 内联 assembly |
| 代码量 | 主合约 ~35 行 | 主合约 ~46 行 |
| 安全性 | 无 malleability 检查 | 无(与 raw 等价) |
| 适用 | 学原理 | 想用 OZ ERC721,但仍可优化 |

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/08_offchain_auth/35_Signature
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── ERC721.sol            # 25 课的 raw ERC721
│   ├── ECDSA.sol             # 自写 ECDSA 库
│   └── SignatureNFT.sol      # 原生 SignatureNFT
└── oz/
    └── SignatureNFT.sol      # OZ 版 SignatureNFTOZ
test/
├── raw/Signature.t.sol
└── oz/Signature.t.sol
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 3 个测试全部通过(raw 2 个 + oz 1 个)。

### 步骤 5:重点测试 —— 签名验证(`test/raw/Signature.t.sol`)

```solidity
function testMintWithValidSignature() public {
    bytes32 msgHash = signatureNft.getMessageHash(user1, 0);
    bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));

    uint8 v;
    bytes32 r;
    bytes32 s;
    (v, r, s) = vm.sign(0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b, ethHash);
    bytes memory signature = abi.encodePacked(r, s, bytes1(v));

    signatureNft.mint(user1, 0, signature);
    assertEq(signatureNft.ownerOf(0), user1);
}
```

教学点:
- 私钥 `0x227d...f2b` 对应的公钥 = 部署时传入的 `signer` 地址(由 Foundry 预设)
- `vm.sign(privateKey, digest)` 返回 `(v, r, s)`,是 Foundry 模拟签名的 cheatcode
- `abi.encodePacked(r, s, bytes1(v))` 把 (v, r, s) 拼成 65 字节的签名

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 3 个测试全部 PASS:
  - **raw**: `testMintWithValidSignature`、`testMintWithInvalidSignature`
  - **oz**: `testMintWithValidSignature`

## 8. 常见错误排查

### 错误 1:`mint` 报 "Invalid signature"

- **常见原因**:
  1. 链上链下 hash 计算方式不一致(参数顺序、packed 方式不同)
  2. 忘了加 `"\x19Ethereum Signed Message:\n32"` 前缀
  3. 签名是 (r, s, v) 但合约按 (v, r, s) 解析
  4. 签名时用的私钥对应的公钥地址 != 合约存的 `signer`
- **解决步骤**:用 Foundry cheatcode `vm.sign` 验证一遍,或硬编码 (v, r, s) 与 msgHash 一起对照
- **验证方式**:`testMintWithValidSignature` 用 vm.sign 现签,确保链上链下 hash 一致

### 错误 2:同一签名在两个不同函数下都通过

- **常见原因**:签名没绑定调用上下文,被重放
- **解决步骤**:msgHash 必须包含函数名+参数:`keccak256(abi.encodePacked("mintNFT", user, tokenId))`
- **验证方式**:看 raw `getMessageHash(user, tokenId)` 只绑了 (user, tokenId) —— 严格意义上仍可被"用同一签名给 user1 mint 不同 tokenId",但 `mintedAddress` 防双花保底

### 错误 3:`recoverSigner` 报 "invalid signature length"

- **常见原因**:签名长度不是 65 字节(可能是 64 或 64 + extra data)
- **解决步骤**:`abi.encodePacked(r, s, v)` 拼出 65 字节;或用 `ECDSA.recover` 自动解析
- **验证方式**:`bytes memory signature = abi.encodePacked(r, s, bytes1(v));` 标准格式

### 错误 4:OZ 版也用 ecrecover,没用到 OZ ECDSA 库

- **常见原因**:本项目 oz 版没引入 OZ ECDSA 库
- **解决步骤**:生产项目改成 `import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";` 然后 `ECDSA.recover(hash, sig)`
- **验证方式**:OZ `ECDSA.recover` 自带 s 值 malleability 检查(防 `s → n - s` 伪造)

## 9. 本节总结

- Signature 白名单 = **项目方链下签,用户链上验**,gas 比 Merkle 树略高(签名 65 字节 vs proof O(log N))
- 三段 hash:`原始参数 → msgHash → ethHash → 签名`
- **`"\x19Ethereum Signed Message:\n32"` 前缀防重放**(EIP-191)
- `ecrecover(hash, v, r, s) → address` 是 EVM 预编译(0x01),固定 3000 gas
- 签名 65 字节,assembly 直接解析比 Solidity 数组快
- 与 Merkle 树对比:签名灵活但项目方要签 N 次,树省空间但不便更新
- `vm.sign(privateKey, digest)` 是 Foundry 测试签名的标准 cheatcode
- 生产用 OZ `ECDSA.recover`,内置 malleability 检查

## 10. 课后练习

### 练习 1
为 SignatureNFT 加 **过期时间**:
- leaf 计算改为 `keccak256(abi.encodePacked(account, tokenId, deadline))`
- mint 时校验 `block.timestamp <= deadline`
- 加测试:deadline 为 now+100,vm.warp now+101 后 mint 应 revert

### 练习 2
为 SignatureNFT 加 **链下 nonce 防重放**:
- 加 `mapping(address => uint256) public nonces;`
- leaf 计算改为 `keccak256(abi.encodePacked(account, tokenId, nonces[account]))`
- mint 后 `nonces[account]++`
- 加测试:同一签名二次 mint 应 revert(因 nonce 已变,hash 不匹配)

### 练习 3(进阶)
基于 raw 的 SignatureNFT,实现 **"签多笔交易"**(permit 风格):
- 让用户能一次性签多笔 mint:"我授权 user1 凭此签名 mint 5 个 tokenId"
- 验证链上 `claim(tokenId, signature)`,自动从白名单领取
- 内部用 `mapping(address => uint256) public claimed;` 记录已领数量
- 加测试:签 5 个,user 领 3 个 OK,第 4 个 OK,第 5 个 OK,第 6 个 revert
- 提示:这就是 NFT 项目"链下抽奖+链上批量领"的模式
