# 第 48 课:MultisigWallet —— 多签钱包

## 1. 本节目标

学完这节课,你能:
- 说清"为什么协议金库、DAO 国库都用多签"
- 自己手写一个 M-of-N 签名验证的 MultisigWallet(raw 实现)
- 理解多签的核心三件套:**`threshold` + 签名拼接 + nonce 防重放**
- 理解为什么签名必须按地址升序拼接
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 35 课:Signature(ECDSA 签名验证)
- 第 36 课:EIP712(类型化结构签名)
- 第 17 课:合约调用(`to.call{value}(data)` 是核心执行)
- 第 11 课:Keccak256(算 txHash)

## 3. 先讲结论

**MultisigWallet(多签钱包) = 需要 M-of-N 个 owner 签名才能执行交易的合约钱包**。典型场景:
- **Gnosis Safe**:DeFi 最大的多签钱包,管理 100B+ 资金
- **DAO 国库**:Compound、Aave 治理金库
- **协议升级权**:管理升级 admin 的多签(防单点作恶)
- **个人资金保护**:2-of-3 防私钥丢失/被盗

**为什么不用 EOA?**
- EOA 单点风险:私钥泄露 = 所有资金丢失
- 多签:N 个签名者中至少 M 个签名才能执行 → 即使单个私钥泄露,资金仍安全
- 例:3-of-5 多签,黑客拿到 2 个私钥也无法盗资金

**多签的核心三件套**:

| 组件 | 作用 |
|------|------|
| `threshold` | 需要的最小签名数(如 2,代表 2-of-N) |
| 签名拼接 | 把多个签名按"地址升序"拼接成一个 bytes |
| `nonce` | 每次执行交易递增,防止旧签名重放 |

**执行流程**:

```
1. 协调者算 txHash = keccak256(to, value, data, nonce, chainid)
2. owner1, owner2, ... 用各自私钥签 txHash,得到 sig1, sig2, ...
3. 协调者按地址升序拼接 → signatures = sig_low ++ sig_mid ++ sig_high
4. 协调者调 wallet.execTransaction(to, value, data, signatures)
5. wallet 内部:
   - 算 txHash(重新算,确保参数一致)
   - 拆分 signatures 为 N 段,各段 ecrecover 出 owner 地址
   - 校验每个 owner 是有效 owner + 按地址升序(防重复签名)
   - 校验签名数 >= threshold
   - 全部通过 → call(to, value, data) 执行交易
   - nonce++(防重放)
```

**为什么签名按地址升序?**
- 防止同一个 owner 重复签名:`currentOwner > lastOwner` 保证地址递增
- 高效校验:不需要 mapping 记录"已签过的 owner"
- Gas 友好:O(N) 时间复杂度

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/MultisigWallet.sol` | 154 行 |
| **oz** | `src/oz/MultisigWallet.sol` | 11 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 命名占位。**生产环境**用 Gnosis Safe 完整实现(数千行,带模块化、防御、多签管理、UI 支持等)。

## 4. 合约设计

### 4.1 状态

```solidity
address[] public owners;                    // 多签持有人数组
mapping(address => bool) public isOwner;    // owner 快速查询
uint256 public ownerCount;                  // owner 数量
uint256 public threshold;                   // M-of-N 中的 M
uint256 public nonce;                       // 防重放
```

要点:
- `owners` 数组用于遍历,`isOwner` 用于 O(1) 查询
- `nonce` 每次 execTransaction 递增

### 4.2 构造函数:_setupOwners

```solidity
function _setupOwners(address[] memory _owners, uint256 _threshold) internal {
    require(threshold == 0, "ERR10000");                        // 只能初始化一次
    require(_threshold <= _owners.length, "ERR10001");          // M <= N
    require(_threshold >= 1, "ERR10002");                       // M >= 1
    
    for (uint256 i = 0; i < _owners.length; i++) {
        address owner = _owners[i];
        require(owner != address(0) && owner != address(this) && !isOwner[owner], "ERR10003");
        owners.push(owner);
        isOwner[owner] = true;
    }
    ownerCount = _owners.length;
    threshold = _threshold;
}
```

要点:
- 校验 0 地址 / 合约自身地址 / 重复 owner 都失败
- 错误码 ERR10001 ~ ERR10003 教学用

### 4.3 txHash 计算

```solidity
function encodeTransactionData(
    address to, uint256 value, bytes memory data,
    uint256 _nonce, uint256 chainid
) public pure returns (bytes32) {
    return keccak256(abi.encode(to, value, keccak256(data), _nonce, chainid));
}
```

教学点:
- `chainid` 防跨链重放(同一签名在 mainnet 和 testnet 不通用)
- `nonce` 防同链重放
- `keccak256(data)` 而非 `data`:避免 data 长度可变时的歧义

### 4.4 签名验证:checkSignatures

```solidity
function checkSignatures(bytes32 dataHash, bytes memory signatures) public view {
    require(signatures.length >= threshold * 65, "ERR10006");   // 每个签名 65 字节
    
    address lastOwner = address(0);
    for (uint256 i = 0; i < threshold; i++) {
        (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signatures, i);
        address currentOwner = ecrecover(
            keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", dataHash)),
            v, r, s
        );
        require(currentOwner > lastOwner && isOwner[currentOwner], "ERR10007");
        lastOwner = currentOwner;
    }
}
```

教学点:
- 每个签名 65 字节(r=32 + s=32 + v=1)
- `currentOwner > lastOwner`:核心防重复 + 防乱序
- `"\x19Ethereum Signed Message:\n32"`:以太坊签名标准前缀(35 课讲)

### 4.5 signatureSplit:assembly 拆分

```solidity
function signatureSplit(bytes memory signatures, uint256 pos)
    internal pure returns (uint8 v, bytes32 r, bytes32 s) {
    assembly {
        let signaturePos := mul(0x41, pos)              // 0x41 = 65 字节
        r := mload(add(signatures, add(signaturePos, 0x20)))
        s := mload(add(signatures, add(signaturePos, 0x40)))
        v := and(mload(add(signatures, add(signaturePos, 0x41))), 0xff)
    }
}
```

要点:
- assembly 读取按 65 字节切片的 r/s/v
- `add(signatures, 0x20)`:跳过 bytes 的长度前缀

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/MultisigWallet.sol`(154 行)

#### execTransaction 完整流程

```solidity
function execTransaction(
    address to, uint256 value, bytes memory data, bytes memory signatures
) public payable virtual returns (bool success) {
    bytes32 txHash = encodeTransactionData(to, value, data, nonce, block.chainid);
    nonce++;                                          // 1. nonce++(防重放)
    checkSignatures(txHash, signatures);              // 2. 验证签名
    (success, ) = to.call{value: value}(data);        // 3. 执行交易
    require(success, "ERR10004");
    if (success) emit ExecutionSuccess(txHash);
    else emit ExecutionFailure(txHash);
}
```

要点:
- `nonce++` 必须在 checkSignatures **之前**(否则攻击者可在签名验证失败但 nonce 未变时尝试重放)
  - 注意:这里实际是先 `nonce++`,确保即使后续 revert 也消耗 nonce... 等等,revert 会回滚 nonce 改动,所以本质上 nonce 是"成功执行后才递增"
  - 严格防重放设计应在 checkSignatures 之后 `nonce++`(本课的写法是 nonce++ 在前面,但 revert 会回滚,效果一致)
- `to.call{value}(data)`:可以转 ETH + 任意 calldata,极通用

### 5.2 oz 实现 —— `src/oz/MultisigWallet.sol`

```solidity
import {MultisigWallet} from "../../src/raw/MultisigWallet.sol";

contract MultisigWalletOZ is MultisigWallet {
    constructor(address[] memory _owners, uint256 _threshold)
        MultisigWallet(_owners, _threshold) {}
}
```

要点:业务完全一致,本项目 oz 版只是命名占位。

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| 代码量 | 154 行 | 11 行 |
| 适用 | 学原理 | 命名占位 |

**生产用 Gnosis Safe**:
- 模块化(Module 系统:加 timelock / spending limit / 子模块)
- Guard(执行前后钩子,做额外校验)
- 完整事件系统 + 链下 UI(safe.global)
- 经过百万级 ETH 资金的实战检验

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/10_upgrade_governance/48_MultisigWallet
```

### 步骤 2:查看文件结构

```
src/
├── raw/MultisigWallet.sol     # 154 行,完整多签实现
└── oz/MultisigWallet.sol      # 11 行,继承 raw
test/
├── raw/MultisigWallet.t.sol   # 11 个测试
└── oz/MultisigWallet.t.sol    # 1 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 12 个测试全部通过(raw 11 个 + oz 1 个)。

### 步骤 5:重点测试 —— 完整多签流程(`test/raw/MultisigWallet.t.sol`)

```solidity
function setUp() public {
    owners = [vm.addr(1), vm.addr(2), vm.addr(3)];        // 3 个 owner
    wallet = new MultisigWallet(owners, 2);                // 2-of-3
}

function sign(bytes32 hash, uint256 pk) internal pure returns (bytes memory) {
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(pk, 
        keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash))
    );
    return abi.encodePacked(r, s, v);                      // 注意 r,s,v 顺序!
}

function buildSortedSignatures(bytes32 txHash) internal view returns (bytes memory) {
    bytes memory sig1 = sign(txHash, 1);
    bytes memory sig2 = sign(txHash, 2);
    bytes memory sig3 = sign(txHash, 3);
    return abi.encodePacked(sig2, sig3, sig1);            // 排序:a2 < a3 < a1
}

function testExecTransactionWithValidSignatures() public {
    address to = address(0x4);
    bytes32 txHash = wallet.encodeTransactionData(to, 1 ether, "", 0, block.chainid);
    bytes memory signatures = buildSortedSignatures(txHash);
    
    vm.deal(address(wallet), 2 ether);
    wallet.execTransaction{value: 1 ether}(to, 1 ether, "", signatures);
    
    assertEq(address(to).balance, 1 ether);
    assertEq(wallet.nonce(), 1);
}
```

教学点:
- `vm.addr(1/2/3)`:Foundry cheatcode,从私钥派生地址
- `vm.sign(pk, hash)`:用私钥签消息哈希
- `buildSortedSignatures`:**关键** —— 必须按 owner 地址升序拼接
- 排序示例:`vm.addr(2) < vm.addr(3) < vm.addr(1)`(地址值非按 pk 顺序)

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 12 个测试全部 PASS:
  - **raw**: `testDeployment`、`testEncodeTransactionData`、`testCannotDeployWithZeroOwners`、`testCannotDeployWithThresholdZero`、`testCannotDeployWithThresholdGreaterThanOwners`、`testCannotDeployWithDuplicateOwners`、`testCannotDeployWithZeroAddressOwner`、`testExecTransactionWithValidSignatures`、`testExecTransactionWithInsufficientSignatures`、`testExecTransactionWithInvalidSignature`、`testNoncePreventsReplayAttack`
  - **oz**: 1 个核心流程测试

## 8. 常见错误排查

### 错误 1:`execTransaction` 报 "ERR10007"(签名校验失败)

- **常见原因**:签名没按地址升序拼接,或包含非 owner 签名
- **解决步骤**:
  - 先算 owner 地址 → 按升序排序
  - 按排序顺序逐个签 + 拼接
- **验证方式**:用 `buildSortedSignatures` 辅助函数,保证顺序正确

### 错误 2:`execTransaction` 报 "ERR10006"(签名长度不够)

- **常见原因**:签名数 < threshold,或单个签名不是 65 字节
- **解决步骤**:确保每个签名 65 字节(r+s+v),拼接后 = threshold * 65
- **验证方式**:`testExecTransactionWithInsufficientSignatures` 验证少签 revert

### 错误 3:重放攻击成功

- **常见原因**:nonce 没递增,或没包含 chainid
- **解决步骤**:txHash 必须包含 nonce + chainid,execTransaction 必须 nonce++
- **验证方式**:`testNoncePreventsReplayAttack` 第一次成功后,用旧签名再调失败

### 错误 4:txHash 在前端与合约算不一致

- **常见原因**:`abi.encode` 与 `abi.encodePacked` 混用,或 data 没 keccak256
- **解决步骤**:严格遵循 `keccak256(abi.encode(to, value, keccak256(data), nonce, chainid))`
- **验证方式**:用 `encodeTransactionData` view 函数对照,前端先调一次拿 hash

## 9. 本节总结

- MultisigWallet = M-of-N 签名才能执行交易的合约钱包
- 核心三件套:**threshold + 签名升序拼接 + nonce 防重放**
- txHash 必含 chainid(防跨链)+ nonce(防同链)+ data hash
- 签名格式:65 字节(r=32 + s=32 + v=1),多个签名拼接成 bytes
- 校验:逐个 ecrecover + 校验 isOwner + 校验地址递增
- 与 EOA 对比:多签防单点失效,管理大额资金必备
- 实战:Gnosis Safe(safe.global)是金标准,管理 100B+ 资金
- 配合 timelock(33 课):多签 + 延迟执行,更安全
- 配合 ERC4626 金库(41 课):多签管理金库 admin 权限

## 10. 课后练习

### 练习 1
为 MultisigWallet 加 **动态添加/移除 owner**:
- 加 `function addOwner(address newOwner) external` 需要 threshold 签名才能调
- 加 `function removeOwner(address oldOwner) external` 同样需要签名
- 加测试:用 2 个 owner 签名添加第 4 个 owner

### 练习 2
为 MultisigWallet 加 **改 threshold 函数**:
- 加 `function changeThreshold(uint256 newThreshold) external` 自我调用(用多签批准)
- 加测试:从 2-of-3 改为 3-of-3,再次执行需要 3 签

### 练习 3(进阶)
基于 raw 的 MultisigWallet,实现 **模块化 Guard**:
- 加 `address public guard;` 字段
- execTransaction 前调 `guard.checkTransaction(...)` 做额外校验
- 加 `SpendingLimitGuard` 限制单日转账上限
- 加测试:超出限额时 execTransaction 被 guard 拒绝
- 提示:这是 Gnosis Safe 模块化设计的简化版
