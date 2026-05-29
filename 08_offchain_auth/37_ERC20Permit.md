# 第 37 课:ERC20Permit —— EIP-2612 离线授权

## 1. 本节目标

学完这节课,你能:
- 说清"为什么 ERC20 需要 Permit(链下授权),传统 approve 为什么落后"
- 自己手写一个支持 EIP-2612 的 ERC20(raw 实现)
- 理解 EIP-2612 五个签名字段:`owner / spender / value / nonce / deadline`
- 用 Foundry `vm.sign` + `vm.addr` 模拟 owner 签名
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 36 课:EIP-712(本课是 EIP-712 在 ERC20 上的具体应用)
- 第 24 课:ERC20 同质化代币(本课在 ERC20 基础上加 permit)
- 第 35 课:Signature(eth_sign 与 EIP-712 是不同签名标准)

## 3. 先讲结论

**ERC20Permit = EIP-2612,在 ERC20 上加 `permit()` 函数,让用户链下签名授权,spender 一次交易完成"授权 + 后续操作"**。典型场景:
- **Uniswap V3 添加流动性**:用户签 permit,router 一次交易完成"approve + mint"
- **Aave V3 存款**:用户签 permit,aave 一次交易完成"approve + deposit"
- **Permit2(Uniswap)**:通用 permit,支持任意 ERC20
- **节省 gas**:用户不需要先发 approve 交易

**传统两步流程 vs Permit 一步流程**:

```
传统两步(用户先 approve,spender 再 transferFrom):
  1. user.approve(spender, amount)         ← 用户付 gas,21k+50k
  2. spender.transferFrom(user, amount)    ← spender 付 gas,21k+50k
  共 2 笔交易

Permit 一步(用户链下签,spender 一笔交易搞定):
  1. user 在钱包签 "Permit(owner, spender, value, nonce, deadline)"  ← 不上链,无 gas
  2. spender 调 permit(...) + 业务逻辑(transferFrom / addLiquidity / deposit)  ← 一笔
  共 1 笔链上交易(且用户无 gas)
```

**EIP-2612 五个签名字段**(钱包显示为表格):

| 字段 | 含义 | 作用 |
|------|------|------|
| `owner` | token 持有者 | 必须与签名者地址一致 |
| `spender` | 被授权方 | 谁能调 `transferFrom` |
| `value` | 授权额度 | 可以是任意 uint256 |
| `nonce` | 防重放序号 | 每用一次 +1 |
| `deadline` | 过期时间 | `block.timestamp <= deadline` 才有效 |

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/ERC20Permit.sol` + `ECDSA.sol` | ~121 + 31 行 |
| **oz** | `src/oz/ERC20Permit.sol` | ~10 行(继承 raw) |

> 注:本项目 oz 版直接继承 raw 加 OZ 后缀(本项目未引入 OZ 库)。**生产环境**用 OZ `ERC20Permit.sol`(继承 EIP712 + Nonces),自带 `DOMAIN_SEPARATOR` / `nonces` / `permit` 等。

## 4. 合约设计

### 4.1 状态(标准 ERC20 + permit 字段)

```solidity
// ERC20 标准字段
string public name;                          // "TestToken"
string public symbol;                        // "TT"
uint8 public decimals;                       // 18
uint256 public totalSupply;
mapping(address => uint256) public balanceOf;
mapping(address => mapping(address => uint256)) public allowance;

// EIP-2612 permit 字段
bytes32 public DOMAIN_SEPARATOR;             // 部署时计算
mapping(address => uint256) public nonces;   // 防重放序号
```

### 4.2 permit 函数

```solidity
function permit(
    address owner, address spender, uint256 value, uint256 deadline,
    uint8 v, bytes32 r, bytes32 s
) external {
    require(block.timestamp <= deadline, "ERC20Permit: expired deadline");
    
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH, owner, spender, value, nonces[owner], deadline
    ));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", DOMAIN_SEPARATOR, structHash));
    address signer = digest.recover(v, r, s);
    require(signer == owner, "ERC20Permit: invalid signature");
    
    nonces[owner]++;
    _approve(owner, spender, value);
}
```

教学点:
- **deadline 校验**:过期 permit 失效
- **structHash 五个字段顺序**与 `PERMIT_TYPEHASH` 声明必须一致
- **`signer == owner` 校验**:防止"用别人私钥签自己被授权"
- **`nonces[owner]++`**:每次成功 permit 后 +1,旧签名自动失效
- **最后调 `_approve`**:把 allowance 写进标准 ERC20 状态,后续 `transferFrom` 走标准逻辑

### 4.3 与 EIP-712(36 课)的关系

```
EIP-712(36 课)是"签名标准":如何用结构化数据签名
EIP-2612(本课)是"应用层规范":在 ERC20 上如何用 EIP-712 实现离线授权

Permit 流程:
  EIP-2612 规定 5 个字段
       ↓
  EIP-712 计算 digest(用 PERMIT_TYPEHASH,owner,spender,value,nonce,deadline)
       ↓
  ECDSA 签名(digest + 私钥) → (v, r, s)
       ↓
  链上 permit() 验签 + 设 allowance
```

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/ERC20Permit.sol`

#### constructor 算 DOMAIN_SEPARATOR
```solidity
constructor(string memory _name, string memory _symbol) {
    name = _name; symbol = _symbol; decimals = 18;
    DOMAIN_SEPARATOR = keccak256(abi.encode(
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
        keccak256(bytes(_name)),
        keccak256(bytes("1")),
        block.chainid,
        address(this)
    ));
}
```

要点:
- `name` 是合约名(用户签 permit 时钱包显示),`version` 一般是 "1"
- `block.chainid` 防跨链重放
- `address(this)` 防跨合约重放

#### permit:五段校验
```solidity
function permit(...) external {
    require(block.timestamp <= deadline, "...");                         // 1. 过期校验
    
    bytes32 structHash = keccak256(abi.encode(
        PERMIT_TYPEHASH, owner, spender, value, nonces[owner], deadline
    ));                                                                   // 2. 算 structHash
    bytes32 digest = keccak256(abi.encodePacked(
        "\x19\x01", DOMAIN_SEPARATOR, structHash
    ));                                                                   // 3. 算 digest
    address signer = digest.recover(v, r, s);                              // 4. 恢复签名
    require(signer == owner, "...");                                      // 5. 验签
    
    nonces[owner]++;                                                      // 6. 防重放
    _approve(owner, spender, value);                                      // 7. 设 allowance
}
```

#### _approve / _transfer / _spendAllowance:标准 ERC20 内部
- `_approve`:写 `allowance[owner][spender] = amount` + emit Approval
- `_transfer`:扣 balance + 加 balance + emit Transfer
- `_spendAllowance`:扣 allowance(如果 == `type(uint256).max` 则视为无限授权,不扣)

#### mint:测试用(生产应加权限控制)
```solidity
function mint(address to, uint256 amount) external {
    _mint(msg.sender, to, amount);
}
```

教学点:`msg.sender` 当 `from`,emit `Transfer(msg.sender, to, amount)` —— 模拟"凭空铸造"。生产中必须加 `onlyOwner` 等权限控制。

### 5.2 oz 实现 —— `src/oz/ERC20Permit.sol`

```solidity
import {ERC20Permit} from "../../src/raw/ERC20Permit.sol";

contract ERC20PermitOZ is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol) {}
}
```

要点:
- 业务行为完全一致
- 本项目 oz 版只是"加 OZ 后缀命名"作为占位

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 ERC20 + permit | 继承 raw |
| DOMAIN_SEPARATOR | 在 constructor 中算 | 继承 raw |
| 代码量 | ~121 行 | ~10 行 |
| 适用 | 学原理 | 想要 OZ 命名风格 |

**生产用 OZ 官方 `ERC20Permit.sol`**:继承 `ERC20` + `EIP712` + `Nonces`,Permit 逻辑一行搞定,DOMAIN_SEPARATOR 也内置。

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/08_offchain_auth/37_ERC20Permit
```

### 步骤 2:查看文件结构

```
src/
├── raw/
│   ├── ECDSA.sol             # 扩展版 ECDSA(同 EIP-712 课)
│   └── ERC20Permit.sol       # 原生 ERC20 + Permit
└── oz/
    └── ERC20Permit.sol       # OZ 版(继承 raw)
test/
├── raw/ERC20Permit.t.sol
└── oz/ERC20Permit.t.sol
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

### 步骤 5:重点测试 —— permit 完整流程(`test/raw/ERC20Permit.t.sol`)

```solidity
function testPermit() public {
    token.mint(ownerAddr, 1000e18);
    
    uint256 value = 500e18;
    uint256 deadline = type(uint256).max;   // 不过期
    uint256 nonce = token.nonces(ownerAddr);  // 0

    bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
    bytes32 structHash = keccak256(abi.encode(
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
        ownerAddr, spender, value, nonce, deadline
    ));
    bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
    
    vm.prank(spender);
    token.permit(ownerAddr, spender, value, deadline, v, r, s);

    assertEq(token.allowance(ownerAddr, spender), value);  // ← allowance 已设
    assertEq(token.nonces(ownerAddr), nonce + 1);            // ← nonce 自增
}
```

教学点:
- 链下:owner 用私钥对 digest 签(模拟钱包签 permit)
- 链上:任何人都能调 `token.permit(...)`(本测试是 spender 调),spender 付 gas
- 验证:allowance 生效 + nonce 自增

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 8 个测试全部 PASS:
  - **raw**: `testInitialState`、`testMint`、`testTransfer`、`testPermit`、`testPermitWithInvalidSignature`
  - **oz**: `testInitialState`、`testMint`、`testPermit`

## 8. 常见错误排查

### 错误 1:`permit` 报 "ERC20Permit: invalid signature"

- **常见原因**:
  1. 链上链下 typeHash 不一致
  2. nonce 取错(签时是 0,permit 时已用过)
  3. chainId 不一致(主网 vs 测试网)
  4. 签名用的私钥 != owner 私钥
- **解决步骤**:硬编码所有中间值,逐字节对比
- **验证方式**:`testPermit` 显式构造 digest

### 错误 2:`permit` 报 "ERC20Permit: expired deadline"

- **常见原因**:`block.timestamp > deadline`
- **解决步骤**:把 deadline 设大点(`type(uint256).max`),或 `vm.warp` 回退
- **验证方式**:`testPermit` 用 `type(uint256).max` 作 deadline

### 错误 3:钱包(测试 vm.sign)签的地址 ≠ owner

- **常见原因**:`vm.sign(privateKey, digest)` 必须用 `ownerAddr = vm.addr(privateKey)` 对应的私钥
- **解决步骤**:setUp 中 `ownerAddr = vm.addr(ownerPrivateKey)`,测试用 `vm.sign(ownerPrivateKey, ...)`
- **验证方式**:`vm.addr(0x227d...f2b)` 应等于 ownerAddr

### 错误 4:perm 之后 transferFrom 失败

- **常见原因**:permit 失败但被忽略,或 nonce 没自增导致下次签失败
- **解决步骤**:perm 前 nonce = 0,perm 后 nonce = 1,下次签必须用 nonce = 1
- **验证方式**:`testPermit` 中 `assertEq(token.nonces(ownerAddr), nonce + 1)`

## 8.5 本课安全边界

> 集中安全知识见第 20 课(常见漏洞与防护),本节只列**与 Permit / 签名验签直接相关**的坑点。

### 坑 1:`ecrecover` 返回 0 地址 ≠ 签名失败

**现象**:`ecrecover(digest, v, r, s)` 在 v/r/s 越界 / 无效时 **不会 revert,直接返回 `address(0)`**。如果代码写:
```solidity
address signer = ecrecover(digest, v, r, s);
require(signer == owner, "Invalid");  // 攻击者把 v/r/s 全填 0
```
→ `signer = address(0)`,`address(0) == owner` **永远不会成立**(除非 owner 真的是 0 地址),看起来没事 —— 但如果 owner 真的是 `address(0)`(某些代理场景),就**完全绕过**了。

**修复**(OZ `ECDSA.recover` 已做):
```solidity
address signer = ECDSA.recover(digest, v, r, s);
if (signer == address(0) || signer != owner) revert InvalidSignature();
```

OZ 5.x 的 `ECDSA.recover` 已经拒绝返回 0 地址,**直接用库**,不要自己写 ecrecover。

### 坑 2:签名可跨链 / 跨合约重放

**现象**:Alice 在主网签了 permit(给 spender 授权 100),如果直接复制到 Polygon 同一份合约,**EIP-712 签名校验照样通过**,因为:
- v/r/s 一样
- digest 一样(没带 chainId)
- owner 一样

**修复**:`DOMAIN_SEPARATOR` 必带 `block.chainid` 和 `address(this)`:
```solidity
keccak256(abi.encode(
    keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"),
    keccak256(bytes(name)),
    keccak256(bytes("1")),
    block.chainid,         // ← 防跨链
    address(this)          // ← 防跨合约
))
```

本课 37 已经做了,生产必须不能省。

### 坑 3:用 `type(uint256).max` 当 deadline

**现象**:`deadline = type(uint256).max` 看上去"永不过期很安全",实际是:
- 签名一旦泄漏,**永久有效**,攻击者可以等 N 年后偷
- 用户没法"反悔" —— 签名出去就收不回来

**修复**:用**短窗口**:
```solidity
uint256 deadline = block.timestamp + 15 minutes;  // 15 分钟
```

钱包(MetaMask)签 permit 时一般默认显示这个值,让用户看清"X 分钟后过期"。

### 坑 4:nonce 不递增 = 签名可重放

**现象**:`permit(...)` 成功后没自增 `nonces[owner]`,同一笔签名可以被链上反复调用(尽管 spender 拿了 allowance,但其它操作可以基于这个 allowance 多次 transferFrom)。

**修复**:成功 permit 后 `nonces[owner]++`(本课代码已做)。**每次签名用对应 nonce,验签后 nonce +1,旧签名作废**。

### 坑 5:permit 之后 spender 不来用 = 死信

**现象**:Alice 签了 permit(value=1000)给 spender,但 spender **永远没来调**。Alice 想撤,却没法:
- 链上没记录这笔"待用授权"
- Alice 自己也**没法主动撤销**(必须再 approve(0) 或在 spender 来之前抢跑)

**修复**:
- 用户角度:在 deadline 前观察签名是否被上链,过期就安全
- 协议角度:加 `revoke()` 函数让用户强制把 allowance 设回 0

### 坑 6:在 permit 里 `value` 传 `type(uint256).max` 表无限授权

**现象**:permit(value=2²⁵⁶-1) 在合约里被当成"无限授权"。如果 spender 被黑,用户全部代币被盗。

**修复**:
- 协议支持(OZ 标准):`_spendAllowance` 检测 `currentAllowance != type(uint256).max` 才扣
- 用户角度:别用 max,每次按需

### 关键防御清单

| 风险 | 防御 |
|------|------|
| ecrecover 返回 0 | 用 OZ `ECDSA.recover`,显式检查 0 地址 |
| 跨链/跨合约重放 | DOMAIN_SEPARATOR 带 chainId + verifyingContract |
| deadline 过长 | 用短窗口(15 分钟) |
| nonce 不增 | permit 后 `nonces[owner]++` |
| 死信 | 暴露 `revoke()`,用户在 deadline 前观察 |
| 无限授权 | 协议不强制,但用户要避免 |
| 签名泄漏 | 钱包不要存无限期 permit |

> 集中讲重放 / 跨链攻击的还有第 35 课(Signature),本节聚焦在 Permit 场景。

## 9. 本节总结

- EIP-2612 Permit = **链下签名授权 + 链上一次完成"授权+操作"**
- 节省 1 笔链上交易(用户连 ETH 都不需要)
- 五段签名:`owner / spender / value / nonce / deadline`
- 钱包显示可读表格(EIP-712 字段),非 hex
- 三层防护:deadline 过期 + nonce 重放 + 域分隔(跨链/跨合约)
- permit 后 allowance 走标准 ERC20 路径,后续 transferFrom 照常
- 实战:Uniswap / Aave / Permit2 / Seaport 都支持
- 与 EIP-712(36 课)关系:Permit 是 EIP-712 的"ERC20 应用层"
- 生产用 OZ `ERC20Permit.sol`(继承 EIP712 + Nonces)
- 写 Permit 最常踩的坑:ecrecover 0、跨链重放、deadline 过长、nonce 不增、max 无限授权

## 10. 课后练习

### 练习 1
为 ERC20Permit 加 **批量 permit**:
- 暴露 `function multiPermit(PermitData[] calldata permits) external`
- `PermitData { address owner; address spender; uint256 value; uint256 deadline; uint8 v; bytes32 r; bytes32 s; }`
- 循环调用内部 _permit 节省 gas
- 加测试:Alice 一次性签 2 个不同 spender,multiPermit 后两个 allowance 都生效

### 练习 2
为 ERC20Permit 加 **permit + transferFrom 一笔完成**:
- 暴露 `function permitAndTransferFrom(...)` 一次交易内 "permit + 业务转账"
- 给用户节省一步 RPC 调用
- 加测试:Alice 签 permit(value=500e18) + transferFrom(Alice → Bob, 100e18),验证 Bob 收到 100 token

### 练习 3(进阶)
基于 raw 的 ERC20Permit,实现 **"permit 时把 value 设为 max(uint256) 表示无限授权"**:
- 已有 ERC20 标准:`allowance == type(uint256).max` 表示无限
- 让用户在签 permit 时可以用 value = max 表示"无额度限制"
- `_spendAllowance` 中检查 `currentAllowance != type(uint256).max` 才扣减
- 加测试:value = type(uint256).max,允许 transferFrom 多次,余额足够时一直成功
