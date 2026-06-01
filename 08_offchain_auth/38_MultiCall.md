# 第 38 课:MultiCall —— 批量调用聚合器

## 1. 本节目标

学完这节课,你能:
- 说清"为什么前端/钱包/DeFi 工具都需要 MultiCall"
- 自己手写一个支持 `allowFailure` 标志的 MultiCall(raw 实现)
- 理解 `Call { target, allowFailure, callData }` 三件套的设计
- 用 `abi.encodeWithSignature` 构造子调用 calldata
- 跑通本项目的全部单元测试

## 2. 前置知识

- 第 17 课:合约调用(`address.call(bytes)` 是 MultiCall 的基础)
- 第 18 课:ABI 编码(`abi.encodeWithSignature` 把函数签名 + 参数 → calldata)
- 第 8 课:数组与结构体(`Call[] calldata` 是入参,`Result[] memory` 是出参)

## 3. 先讲结论

**MultiCall = 把多次合约调用打包成一次交易(写)或一次 RPC(读),atomic 原子性 + 省 gas**。典型场景:
- **Etherscan 读取**:一次查"地址的 ETH / USDT / NFT 余额",3 个 `eth_call` → 1 个
- **DeFi 聚合器**:1inch 一次报价多个 DEX
- **NFT 项目批量操作**:mint + setApproval + transfer 一次完成
- **前端优化**:页面加载时一次拉取所有"用户余额、allowance、stake 数据"

**为什么要打包?**
- **读**:每次 RPC 调用 200ms,10 次 = 2s 用户等待;MultiCall 1 次 = 200ms
- **写**:每笔交易基础 21k gas,N 笔 = 21k × N;MultiCall 1 笔 = 21k + N×子调用
- **原子性**:MultiCall 内子调用全部成功或全部 revert(可配 allowFailure)

**核心结构体**:

```solidity
struct Call { address target; bool allowFailure; bytes callData; }
struct Result { bool success; bytes returnData; }
```

`allowFailure` 是精髓:
- `false`(默认):子调用失败 → 整个 multicall revert(原子性)
- `true`:子调用失败 → 仅记录 `success=false`,继续执行后续调用

本项目同时给出两套实现:

| 版本 | 文件 | 代码量 |
|------|------|--------|
| **raw** | `src/raw/MultiCall.sol` | ~32 行 |
| **oz** | `src/oz/MultiCallOZ.sol` | ~8 行(继承 raw) |

> 注:本项目 oz 版只是"加 OZ 后缀"作为占位。**生产环境用 Multicall3**(`mds1/multicall3`),已被 Etherscan / 1inch / Uniswap 等广泛部署。

## 4. 合约设计

### 4.1 状态

```solidity
// 无状态合约,不需要 storage
contract MultiCall {
    struct Call { address target; bool allowFailure; bytes callData; }
    struct Result { bool success; bytes returnData; }
    
    function multicall(Call[] calldata calls) external returns (Result[] memory returnData) { ... }
}
```

`MultiCall` 本身**无 storage**,纯逻辑处理,部署后只用 code 存储,极省 gas。

### 4.2 业务流程

```
用户:
  构造 Call[] = [
    { target: tokenA, allowFailure: false, callData: transferFrom(...) },
    { target: tokenB, allowFailure: false, callData: transferFrom(...) },
    { target: router,  allowFailure: true,  callData: addLiquidity(...) },  // 失败也继续
  ]
       ↓
调 multicall(calls)
       ↓
循环对每个 call:
  1. (success, data) = target.call(callData)
  2. result[i] = (success, data)
  3. if !allowFailure && !success:
       revert("MultiCall: call failed")   ← 整笔 revert
       ↓
返回 Result[] (每个子调用的 success + returnData)
```

### 4.3 abi.encodeWithSignature 构造 calldata

```solidity
bytes memory callData = abi.encodeWithSignature(
    "transferFrom(address,address,uint256)",
    from, to, amount
);
// = 0x23b872dd 000...  (前 4 字节是 selector "transferFrom(address,address,uint256)" 的 keccak256)
```

要点:
- 第一个参数是函数签名字符串(含参数类型)
- 后面是参数列表
- 输出 = `bytes4(keccak256(sig))` ++ `abi.encode(args)`

## 5. 代码拆解

### 5.1 raw 实现 —— `src/raw/MultiCall.sol`

```solidity
function multicall(Call[] calldata calls) external returns (Result[] memory returnData) {
    uint256 length = calls.length;
    returnData = new Result[](length);  // 预分配结果数组

    for (uint256 i = 0; i < length; i++) {
        Call calldata calli = calls[i];
        (bool success, bytes memory data) = calli.target.call(calli.callData);
        returnData[i] = Result(success, data);

        if (!calli.allowFailure && !success) {
            revert("MultiCall: call failed");
        }
    }
}
```

要点:
- `Call[] calldata` 入参:用户传 calldata 数组(链下 ABI 编码,链上读不复制)
- `new Result[](length)` 预分配结果数组(必须先分配,否则 push 不行)
- `target.call(callData)` 是低级 call,可以调任意合约任意函数
- `Result(success, data)` 是结构体构造语法,把 (bool, bytes) 包成 Result
- **失败判断 + 标志**:`!allowFailure && !success` 才 revert,既保证 allowFailure=true 的容错,又保证默认原子性

### 5.2 oz 实现 —— `src/oz/MultiCallOZ.sol`

```solidity
import {MultiCall} from "../../src/raw/MultiCall.sol";

contract MultiCallOZ is MultiCall {}
```

要点:
- **空继承** —— 没改任何东西,只是命名区分
- 业务行为完全一致
- 本项目 oz 版没引入 OZ 库,因为 OZ 没现成的 MultiCall 库

### 5.3 对照看 —— raw vs oz

| 维度 | raw | oz |
|------|-----|----|
| 业务逻辑 | 自写完整 | 继承 raw(空继承) |
| 代码量 | ~32 行 | ~8 行 |
| 适用 | 学原理 | 想要 OZ 命名风格 |

**生产用 Multicall3**(`mds1/multicall3`):
- 部署在 100+ 链上
- 支持 `aggregate3`(同本课)+ `aggregate3Value`(带 ETH)+ `blockAndAggregate`(同区块读)
- 被 Etherscan / 1inch / Uniswap 等行业工具采用

## 6. 实操步骤

### 步骤 1:进入项目目录

```bash
cd 0xF1/foundry_projects/08_offchain_auth/38_MultiCall
```

### 步骤 2:查看文件结构

```
src/
├── raw/MultiCall.sol        # 原生 MultiCall(~32 行)
└── oz/MultiCallOZ.sol       # OZ 版(继承 raw,~8 行)
test/
├── raw/MultiCall.t.sol      # 自带 TestToken mock + 4 个测试
└── oz/MultiCall.t.sol       # 自带 TestToken mock + 1 个测试
```

### 步骤 3:编译

```bash
forge build
```

### 步骤 4:运行测试

```bash
forge test -vv
```

预期 5 个测试全部通过(raw 4 个 + oz 1 个)。

### 步骤 5:重点测试 —— 批量 transferFrom(`test/raw/MultiCall.t.sol`)

```solidity
function testMulticallMultipleCalls() public {
    token0.mint(address(this), 1000e18);
    token1.mint(address(this), 1000e18);
    
    token0.approve(address(multicall), 100e18);   // 授权 multicall
    token1.approve(address(multicall), 200e18);
    
    bytes memory data0 = abi.encodeWithSignature(
        "transferFrom(address,address,uint256)", address(this), address(0x1234), 100e18
    );
    bytes memory data1 = abi.encodeWithSignature(
        "transferFrom(address,address,uint256)", address(this), address(0x5678), 200e18
    );

    MultiCall.Call[] memory calls = new MultiCall.Call[](2);
    calls[0] = MultiCall.Call({target: address(token0), allowFailure: false, callData: data0});
    calls[1] = MultiCall.Call({target: address(token1), allowFailure: false, callData: data1});

    MultiCall.Result[] memory results = multicall.multicall(calls);
    assertTrue(results[0].success);
    assertTrue(results[1].success);
    assertEq(token0.balanceOf(address(0x1234)), 100e18);
    assertEq(token1.balanceOf(address(0x5678)), 200e18);
}
```

教学点:
- `abi.encodeWithSignature("transferFrom(address,address,uint256)", ...)` 把函数选择器 + 参数编码成 calldata
- 授权给 `multicall` 合约,让 multicall 内部能调 token 的 `transferFrom`
- 一次 multicall 调两个 token 的 transferFrom → 两个 result 都 success

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 5 个测试全部 PASS:
  - **raw**: `testMulticallSingleCall`、`testMulticallMultipleCalls`、`testMulticallWithAllowFailure`、`testMulticallRevertOnFailure`
  - **oz**: `testMulticall`

## 8. 常见错误排查

### 错误 1:`multicall` 报 "MultiCall: call failed"

- **常见原因**:
  1. 子调用的 target 没授权给 multicall
  2. 子调用的参数错误
  3. 子调用的业务逻辑失败(如余额不足)
- **解决步骤**:把对应子调用的 `allowFailure` 设为 `true`,看具体哪个失败;或先单独调那个子调用 debug
- **验证方式**:`testMulticallRevertOnFailure` 显式测了"失败 → 整笔 revert"

### 错误 2:`abi.encodeWithSignature` 拼错函数签名

- **常见原因**:类型字符串写错(漏空格、大小写错)
- **解决步骤**:
  - 正确:`"transferFrom(address,address,uint256)"`
  - 错误:`"transferFrom(address, address, uint256)"`(多了空格)
  - 错误:`"transferfrom(address,address,uint256)"`(大小写错)
- **验证方式**:在 console.log 输出 callData 前 4 字节,对比预期 selector(`bytes4(keccak256("transferFrom(address,address,uint256)"))`)

### 错误 3:授权了 tokenA 给 multicall,但 multicall 调的是 tokenB

- **常见原因**:每个子调用前都必须有对应 token 的 allowance
- **解决步骤**:
  ```solidity
  tokenA.approve(address(multicall), amountA);  // 调 tokenA 前
  tokenB.approve(address(multicall), amountB);  // 调 tokenB 前
  ```
- **验证方式**:`testMulticallMultipleCalls` 中 token0 和 token1 各自都 approve

### 错误 4:`calldata` 数组长度限制

- **常见原因**:链上交易 calldata 有 ~24KB 上限,子调用太多会超
- **解决步骤**:分批 multicall(每批 ~50-100 个子调用),或优化 callData(用更紧凑的 encoding)
- **验证方式**:Foundry 测试时 `vm.expectRevert` 不会捕获 gas limit 错误,需在主网实测

## 9. 本节总结

- MultiCall = **批量调用聚合器**,节省 RPC 次数(读)和 gas(写)
- `Call { target, allowFailure, callData }` + `Result { success, returnData }` 是行业标准结构
- `allowFailure` 标志:灵活控制"原子性 vs 容错"
- `abi.encodeWithSignature` 构造 calldata 的标准方法
- `address.call(bytes)` 是底层调用,可调任意合约任意函数
- 实战:Multicall3 部署在 100+ 链,Etherscan / 1inch / Uniswap 都用
- 与本单元其他课的关系:本课是"工具型"合约(本身无业务),其他课是"业务型"
- 配合 ERC20Permit(37 课):Permit 后可用 MultiCall 一次完成"授权 + 业务"

## 10. 课后练习

### 练习 1
为 MultiCall 加 **aggregate3-style value 支持**:
- 暴露 `function multicallWithValue(Call[] calldata calls) external payable`
- 校验 `msg.value == sum(calls[i].value)`
- 子调用用 `target.call{value: calli.value}(callData)`
- 加测试:multicall 调一个 payable 函数转 1 ETH,验证 ETH 到达目标

### 练习 2
为 MultiCall 加 **try/catch 子调用**:
- 当子调用 revert 时,**解码 revert 字符串**并放进 Result
- 用 `try target.call(callData) returns (bool, bytes memory)` / `catch (bytes memory reason)`
- 加测试:触发一个 revert 带 "ERC20: insufficient allowance",验证 Result.returnData 含这个字符串

### 练习 3(进阶)
基于 raw 的 MultiCall,实现 **"读聚合器 aggregateStaticCall"**:
- 暴露 `function aggregateStaticCall(Call[] calldata calls) external returns (Result[] memory)`
- 所有 target 必须是 view/pure 函数
- 用 `staticcall` 而非 `call`,确保子调用不能改状态
- 加测试:批量调 3 个 ERC20 的 `balanceOf`,验证返回 3 个 Result
