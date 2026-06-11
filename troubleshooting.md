# 0xF1 Solidity 集中排障手册

## 使用说明

本文档按问题类型分类，收录 Solidity + Foundry 开发中的高频问题。

每个问题条目包含：
1. **报错现象**：具体的错误信息或行为异常
2. **常见原因**：最常见的 1~3 个原因
3. **解决步骤**：明确的操作步骤
4. **验证方式**：确认问题已解决的方法

---

## 一、环境安装类

### 问题 1：foundryup 安装失败

**报错现象**：`curl: command not found` 或 `command not found: foundryup`

**常见原因**：
- 系统没有 curl（Windows 默认没有）
- 网络问题导致下载失败
- PATH 环境变量没有配置

**解决步骤**：
1. Mac/Linux 确认有 curl：`curl --version`
2. Windows 用户建议安装 [WSL2](https://docs.microsoft.com/en-us/windows/wsl/install)
3. 如果网络问题，用国内镜像或等待重试：
   ```bash
   # 方式 1：直接用 curl 安装
   curl -L https://foundry.paradigm.xyz | bash
   foundryup

   # 方式 2：如果网络慢，尝试指定版本
   foundryup -v 0.3.0
   ```

**验证方式**：`forge --version` 有版本号输出

---

### 问题 2：forge 命令不可用（command not found）

**报错现象**：`bash: forge: command not found`

**常见原因**：
- Foundry 没有安装
- 安装后没有刷新 PATH
- 在旧终端窗口中运行（安装后没重启终端）

**解决步骤**：
1. 重新打开一个全新的终端窗口
2. 输入 `forge --version` 测试
3. 如果还是不行，重新运行 `foundryup`
4. 确认 foundry 安装路径在 PATH 中（通常是 `~/.foundry/bin`）

**验证方式**：`forge --version` / `cast --version` / `anvil --version` 全部有输出

---

## 二、编译失败类

### 问题 3：SPDX 许可证声明缺失

**报错现象**：`Warning: SPDX license identifier not provided in source file`

**常见原因**：文件第一行没有写 SPDX 声明

**解决步骤**：在 `.sol` 文件最顶部加一行：
```solidity
// SPDX-License-Identifier: MIT
```

**验证方式**：`forge build` 不再报这个警告

---

### 问题 4：pragma 版本声明缺失

**报错现象**：`Error: Source file does not specify a Solidity version`

**常见原因**：缺少 `pragma solidity` 声明

**解决步骤**：在 SPDX 声明后加：
```solidity
pragma solidity ^0.8.35;
```

**验证方式**：`forge build` 成功

---

### 问题 5：语法错误（缺少分号、括号不匹配）

**报错现象**：`Error: expected ';' but got '}'` 或类似的语法错误

**常见原因**：
- 缺少分号 `;`
- 括号 `{}()` 不匹配
- 关键字拼写错误

**解决步骤**：
1. 看错误信息里的文件名和行号
2. 去对应文件对应行检查
3. 常见错误：for 循环里忘了 `i++`，if 语句后多了分号
4. 逐字检查括号和分号是否匹配

**验证方式**：`forge build` 成功

---

### 问题 6：函数可见性未声明

**报错现象**：`Error: Visibility must be declared for function`

**常见原因**：函数缺少可见性修饰符（external / public / internal / private）

**解决步骤**：给函数加上可见性修饰符：
```solidity
// 错误
function getValue() returns (uint256)

// 正确
function getValue() external view returns (uint256)
```

**验证方式**：`forge build` 成功

---

### 问题 7：数据类型不匹配

**报错现象**：`Error: Type uint256 is not implicitly convertible`

**常见原因**：
- 函数参数类型和实际传入类型不匹配
- 赋值左右类型不一致

**解决步骤**：
1. 检查函数签名中的类型声明
2. 检查调用时的实际传入类型
3. 确认是否需要显式类型转换

**验证方式**：`forge build` 成功

---

## 三、测试失败类

### 问题 8：测试中的 assert 失败

**报错现象**：`[FAIL] testName (gas: XXXXX)` — 断言不等于期望值

**常见原因**：
- 合约逻辑写错了
- 测试的期望值写错了
- 状态没有正确更新

**解决步骤**：
1. 看错误信息，确认是哪个 assertEq 失败
2. 用 `forge test -vvv` 查看详细执行流程
3. 检查合约逻辑是否正确
4. 检查测试的期望值是否正确

**验证方式**：`forge test` 全部 PASS

---

### 问题 9：setUp 失败

**报错现象**：`Error: setUp failed` 或测试运行前就报错

**常见原因**：
- `setUp()` 里部署合约失败
- 合约构造函数 revert 了
- 缺少必要的 import

**解决步骤**：
1. 检查 `setUp()` 里的 `new Contract()` 是否正确
2. 检查构造函数参数是否匹配
3. 确认 import 语句里有 `forge-std/Test.sol`

**验证方式**：`forge test` setUp 不再失败

---

### 问题 10：expectRevert 没触发

**报错现象**：`vm.expectRevert()` 后交易没有 revert，测试失败

**常见原因**：
- `expectRevert` 写在错误的位置
- 要 revert 的代码实际上没执行到
- revert 类型和 expectRevert 写的不匹配

**解决步骤**：
1. 确认 `vm.expectRevert()` 写在 `call` 之前
2. 确认要触发的 revert 类型正确：
   - `vm.expectRevert()` — 捕获任何 revert
   - `vm.expectRevert(ErrorName.selector)` — 捕获自定义 error
   - `vm.expectRevert("reason string")` — 捕获 require 字符串

**验证方式**：`forge test` 正确捕获 revert

---

## 四、ETH 转账类

### 问题 11：转账失败（Transfer failed）

**报错现象**：`require(success, "Transfer failed")` 触发

**常见原因**：
- 接收方合约没有 receive / fallback
- 接收方合约 receive 不为 payable
- gas 不足

**解决步骤**：
1. 确认接收方合约有 `receive() external payable`
2. 使用 `.call{value: amount}("")` 而非 `.transfer()`
3. 检查接收方合约是否是真正的合约地址

**验证方式**：`forge test` 中转账成功

---

### 问题 12：合约无法接收 ETH

**报错现象**：向合约转 ETH 但余额不变

**常见原因**：
- 合约没有 `receive()` 或 `fallback()` 函数
- 或者两个函数没有 `payable` 修饰符

**解决步骤**：给合约添加：
```solidity
receive() external payable {
    // 处理收到的 ETH
}
```

**验证方式**：`forge test` 中直接转账后余额增加

---

## 五、合约调用类

### 问题 13：call 返回 success=false

**报错现象**：`require(success, "Call failed")` 触发

**常见原因**：
- 函数签名不匹配
- 参数类型不匹配
- 目标合约不存在该函数
- 目标合约 revert 了

**解决步骤**：
1. 用 `forge test -vvvv` 打印返回的 rawData
2. 确认函数签名完全一致：`"setValue(uint256)"` 不能写成 `"setValue (uint256)"`
3. 确认参数个数和类型一致

**验证方式**：`forge test` 中 call 成功

---

### 问题 14：abi.decode 类型不匹配

**报错现象**：`abi.decode` 报类型错误

**常见原因**：
- 解码时的类型顺序和编码时不一致
- 解码类型数量和编码参数数量不一致

**解决步骤**：
1. 确认编码时用了几个参数：`abi.encode(a, b, c)` — 3 个
2. 确认解码时类型完全一致：`abi.decode(data, (uint256, address, bytes))`
3. 注意顺序要完全对应

**验证方式**：`forge test` 解码正确

---

## 六、Foundry 命令类

### 问题 15：forge build 找不到文件

**报错现象**：`Error: file not found` 或 `Cannot find contract`

**常见原因**：
- 文件路径拼写错误
- 合约文件名和 `contract` 名不一致
- `src` 目录配置不对

**解决步骤**：
1. 确认文件在 `src/` 目录下
2. 确认 `forge.toml` 里 `src = "src"` 配置正确
3. 确认文件名和合约内的 `contract` 名一致

**验证方式**：`forge build` 成功

---

### 问题 16：forge script 报 network not found

**报错现象**：`Error: network does not exist` 或连不上 RPC

**常见原因**：
- `anvil` 没有启动
- RPC URL 写错了
- 网络隔离（防火墙）

**解决步骤**：
1. 确认 `anvil` 在另一个终端窗口运行中
2. 确认 RPC URL 为 `http://127.0.0.1:8545`（不是 `localhost`）
3. 确认 URL 没有多余空格
4. 如果是远程 RPC，确认 URL 可访问

**验证方式**：`anvil` 保持运行，`forge script` 成功

---

## 七、综合类

### 问题 17：测试通过但合约行为不对

**报错现象**：`forge test` 全部 PASS，但用 `cast call` 实际调用时结果不对

**常见原因**：
- 测试环境中行为和实际链上行为不一致
- 测试里用了 cheatcode（如 `vm.deal`），但实际合约没有用到
- 状态变量默认值在测试和实际中不同

**解决步骤**：
1. 审查测试的 `setUp()` 是否正确模拟了真实场景
2. 不要过度依赖 `vm.deal` 假 ETH，实际场景中 ETH 是真的
3. 用 `forge script` 在 anvil 上实际部署验证

**验证方式**：`anvil` 上 `forge script` + `cast call` 返回正确结果

---

### 问题 18：私钥泄漏或安全问题

**报错现象**：发现私钥写在代码里或 `.env` 文件提交到了 GitHub

**常见原因**：
- 开发时把测试私钥写在代码里
- `.env` 文件没有加到 `.gitignore`

**解决步骤**：
1. 立刻停止使用该私钥（如果是真的）
2. 把私钥从代码移到环境变量
3. 确认 `.gitignore` 包含 `.env`
4. 如果私钥已公开，立即将账号里资产转移到新账号

**验证方式**：`git log` 里确认私钥不再存在

---

---

## 八、代理升级与多签类（第 44~48 课）

### 错误 1：UUPS 升级后合约再也无法升级（"死锁"）

- **典型表现**：升级到 v2 Logic 后,所有升级调用都 revert,且没有任何办法恢复
- **常见原因**：v2 Logic 漏写 `upgrade()` 函数(UUPS 把 upgrade 从 Proxy 搬到 Logic)
- **排查步骤**：
  1. `forge inspect <NewLogic> methods | grep upgrade` —— 确认新 Logic 有 upgrade
  2. 缺失时只能**重新部署**整套 Proxy + Logic(数据丢失)
- **预防**：
  - 用 OZ `UUPSUpgradeable` + `_authorizeUpgrade` hook(编译时强制提醒)
  - 升级前对每个 Logic 版本 grep `upgrade` / `upgradeToAndCall` 关键字
  - 永远**不要**用 UUPS 做"核心金库"(单点不可逆)

### 错误 2：TransparentProxy admin 调业务函数莫名 revert

- **典型表现**：admin 调 `proxy.foo()` 总是失败,但非 admin 调却成功
- **常见原因**：这是**正确行为** —— TransparentProxy 的 fallback 第一行就是 `require(msg.sender != admin)`
- **排查步骤**：
  - 确认是 admin 调 → 应该用 ProxyAdmin 合约身份调
  - 或改用非 admin 账户(配合 `vm.prank`)
- **预防**：admin 永远只调 Proxy 的管理函数(upgrade/transferAdmin)

### 错误 3：升级后数据"消失"或"乱码"

- **典型表现**：升级前余额 X,升级后余额变成 0 或者完全不对
- **常见原因**：新 Logic **改了存储布局**(字段顺序/类型变化),storage 槽位错位
- **排查步骤**：
  1. `forge inspect <OldLogic> storage-layout` 记录旧槽位
  2. `forge inspect <NewLogic> storage-layout` 比对新槽位
  3. 每个字段 slot 编号、类型必须**完全一致**(只能**追加**字段)
- **预防**：升级前用 `forge inspect storage-layout` diff 校验;用 hardhat-upgrades 插件自动检测

### 错误 4：MultisigWallet 调 `execTransaction` 报"ERR10007"

- **典型表现**：明明有足够签名,仍然 revert "ERR10007"
- **常见原因**：签名没按 **owner 地址升序** 拼接
- **排查步骤**：
  1. 用 `ecrecover` 反算每个签名对应的 owner 地址
  2. 检查 `signatures` 拼接顺序是否与 `currentOwner > lastOwner` 单调递增一致
  3. 确认每个 owner 都在 `isOwner` 列表中
- **预防**：写 `buildSortedSignatures` 辅助函数,先算地址再按升序拼

### 错误 5：MultisigWallet 签名"被重放"到其他链

- **典型表现**：在 mainnet 的签名,在 polygon/optimism 也能用
- **常见原因**：txHash 构造时漏了 `chainid` 或 `nonce` 没递增
- **排查步骤**：
  - 校验 `txHash = keccak256(abi.encode(to, value, keccak256(data), nonce, block.chainid))` 五要素齐全
  - 校验 `execTransaction` 内部 `nonce++` 在 checkSignatures 之前
- **预防**：参考第 48 课范例,txHash 五要素缺一不可

### 错误 6：OZ `Initializable` 二次初始化被攻击

- **典型表现**：部署 Proxy 后,initialize 被"中间人"抢调,owner 权限被夺
- **常见原因**：Logic 没继承 `Initializable` 或 initialize 没加 `initializer` modifier
- **预防**：
  - 必须 `is Initializable, UUPSUpgradeable`
  - initialize 必须 `public initializer`(OZ 保证只能调一次)
- **验证方式**：第二次调 initialize 应 revert "InvalidInitialization"

---

## 九、链下签名与 Permit 类（第 35~38 课）

### 错误 1：`ecrecover` 返回 `address(0)`

- **典型表现**：签名验证失败,恢复出 `0x0000...0`
- **常见原因**：
  - 签名 `v` 值不对(27/28 写反)
  - 签名 `s` 值超出 secp256k1 半阶(应 < `0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0`)
  - 用错了 EIP-712 前缀 `\x19Ethereum Signed Message:\n32` 漏了
- **排查步骤**：
  ```solidity
  address recovered = ecrecover(hash, v, r, s);
  require(recovered != address(0), "Invalid signature");
  require(recovered == expectedSigner, "Wrong signer");
  ```
- **预防**：用 OZ `ECDSA.recover(hash, signature)` 自动校验 s 范围

### 错误 2：ERC20Permit 报 "permit expired"

- **典型表现**：用户 permit 后,合约 deadline 已过
- **常见原因**：`deadline` 字段设短了(默认几分钟),用户签了但没立即提交
- **预防**：
  - deadline 留充足窗口(常用 1 小时到 1 天)
  - 前端提示用户"签名 30 分钟内有效"

### 错误 3：EIP-712 钱包提示"unknown sign method"

- **常见原因**：`domainSeparator` 的 `name/version/chainId/verifyingContract` 与合约不一致
- **排查步骤**：
  1. 钱包用 `eip712.domain()` 拉合约定义的域
  2. 校验 `DOMAIN_SEPARATOR()` 合约 view 函数返回值是否一致
  3. 注意每次 `verifyingContract` 地址变化(部署新合约)需要重新签
- **预防**：前端集成 EIP-712 时,**永远用合约的 `DOMAIN_SEPARATOR()` view 函数**生成,不要硬编码

### 错误 4：Merkle 证明验证通过但 claim 失败

- **典型表现**：`verify(proof, leaf)` 返回 true,但实际领取时 revert
- **常见原因**：
  - 链下计算 leaf 的方式(排序/拼接/哈希)与合约不一致
  - 节点排序错(传入的 proof 兄弟节点顺序与构造树时相反)
- **排查步骤**：
  - 链下脚本生成 proof 时,用 `OpenZeppelin StandardMerkleTree` 库
  - 链上校验时,`keccak256(abi.encodePacked(a, b))` 的左右顺序与构造一致
- **预防**：单测覆盖"证明可正常领取"+ 故意改一个字节应 revert

### 错误 5：MultiCall 部分调用 revert 导致整体失败

- **典型表现**：`aggregate(calls)` 整体 revert
- **常见原因**：MultiCall 默认**原子性**(任一失败全回滚)
- **解决**：改用 `tryAggregate(false, calls)` 允许部分失败
- **预防**：业务允许部分失败时,用 `tryAggregate`;严格要求原子性才用 `aggregate`

---

## 十、DeFi 协议类（第 39~43 课）

### 错误 1：DEX swap 后用户收到"几乎为零"代币

- **典型表现**：用 1000 USDC 换 ETH,收到 0.0000001 ETH
- **常见原因**：
  - 算错了 decimals(USDC 6 位,ETH 18 位)
  - 用了 `getAmountOut` 公式但忘了扣手续费(常见 0.3%)
  - 输入参数单位不对(传 wei 还是 ether?)
- **预防**：
  - 统一用 OZ `IERC20Metadata.decimals()` 拿精度
  - 公式:`amountIn * 997 * reserveOut / (reserveIn * 1000 + amountIn * 997)`

### 错误 2：Flashloan "no reentrancy" 但回滚了

- **典型表现**：调用 `flashLoan(receiver, token, amount, data)` 后整个 tx revert
- **常见原因**：
  - 用户的 `executeOperation` 没还钱(还的金额 ≠ 借的金额 + 手续费)
  - 还的 token 地址错了(USDC vs USDT 选错)
  - 还钱的 approve 还没调
- **排查步骤**：
  1. `vm.expectEmit` 抓 FeeCollected 事件校验是否扣费
  2. 在 `executeOperation` 内 `console.log` 还款金额
  3. 检查 `IERC20(token).balanceOf(lender)` 是否回到原值
- **预防**：用 OZ `IFlashLoanReceiver` 接口校验返回值;还款金额必须**严格 = 借款 + 手续费**

### 错误 3：DutchAuction 没人买 / 全被同一人买

- **典型表现**：auction 一开始就被一个用户"秒"
- **常见原因**：没加 commit-reveal / 没限速 / 起始价过低
- **预防**：
  - 起始价设高一些(预售价的 2-3 倍)
  - 衰减函数不要太快(常见 1-7 天线性衰减)
  - 加 `perAddressLimit` 防 sybil

### 错误 4：ERC4626 金库 share 计算舍入误差

- **典型表现**：deposit 100 → mint 99 share(应为 100 share)
- **常见原因**：
  - 第一次 deposit 时 `totalSupply() == 0`,用 `amount * totalSupply() / totalAssets()` 会得到 0
  - 解决:首次 deposit 用 `1:1` 或 `deadShares`(锁定一部分给第一个 depositor)
- **预防**：参考 OZ `ERC4626` 实现的"虚拟 share"防御

### 错误 5：NFTSwap 部分 NFT 已成交,用户整单失败

- **典型表现**：用户想用 NFT A + B 换对方 NFT C,但 B 已被人抢走
- **常见原因**：原子性 swap 中任一 NFT 不可用就 revert
- **解决**：
  - 用户主动接受"拆单"(`partialFill = true`)
  - 或使用 [OpenSea Seaport](https://docs.opensea.io/) 等支持 partial fill 的协议
- **预防**：业务允许"半成交"时,UI 明确提示

---

## 十一、外部系统类（VRF / 跨链,第 49~50 课）

### 错误 1：Chainlink VRF `requestRandomWords` 报 "InvalidSubscription"

- **典型原因**：
  - subscription ID 填错(0 / 已被删除)
  - subscription 没充值 LINK
  - subscription owner 不是当前调用合约
- **排查步骤**：
  1. 到 [vrf.chain.link](https://vrf.chain.link) 确认 subscription 存在 + 有 LINK 余额
  2. 确认 `consumer` 列表里包含本合约地址
  3. 调 `getSubscription(subId)` 校验 owner / balance
- **预防**：生产环境用 [VRF v2.5](https://docs.chain.link/vrf),新版本 API 简化

### 错误 2：VRF `fulfillRandomWords` 回调 "out of gas"

- **典型原因**：`callbackGasLimit` 配低了,业务逻辑又太复杂
- **排查步骤**：
  - 默认 100000 起步,根据 `fulfillRandomWords` 实际消耗设
  - 回调内**只做状态写入**,不调复杂业务
- **预防**：回调内仅 emit 事件 + 写 storage,业务逻辑放在用户主动 `claim()` 函数

### 错误 3：跨链桥中继者"卡住"导致用户资产没到账

- **典型原因**：
  - 中继者节点宕机 / 私钥丢失
  - 源链与目标链 gas 价格差异过大,中继者没钱付 gas
- **排查步骤**：
  1. 监听中继者日志(Discord/Telegram 群)
  2. 手动调 `bridge.mint(user, amount)` 应急
  3. 升级中继者(多签 + 切换)
- **预防**：
  - 用多签中继者(第 48 课)
  - 加每日 mint 上限(防单点故障时大额损失)
  - timelock 关键参数修改

### 错误 4：lock/unlock 后 bridge 合约余额不守恒

- **典型表现**：bridge 持有 100 USDC,目标链流通 100 USDC,但用户能 mint 200 USDC
- **典型原因**:
  - owner 私钥泄露,攻击者绕过 Bridge 事件直接 mint
  - mint 漏写 `onlyOwner` 鉴权
  - 没有 rate limit,大量 mint 时延后到账
- **排查步骤**:
  1. 检查 `mint` / `unlock` 是否带 `onlyOwner` modifier
  2. 检查 owner 是否多签(48 课)
  3. 检查 `Bridge` 事件是否被 relayer 监听(链上日志搜)
- **预防**:多签中继者 + rate limit + timelock + 公开审计

### 错误 5：Chainlink VRF random 恰好为 0,`getRandomResult` revert

- **典型原因**:合约有 `if (random == 0) revert` 防御
- **解决**:
  - 改用 `mapping(uint256 => bool) public requestFulfilled` 单独记录"是否已 fulfill"
  - 不用 random 值本身做状态判断
- **预防**:VRF 返回的 randomWord 理论上可能为 0(极低概率),不要用值本身当 sentinel

---

## 排障优先级建议

遇到问题时，建议按以下顺序排查：

1. **环境问题**（foundry 是否装好）→ `forge --version`
2. **编译问题**（代码语法对不对）→ `forge build`
3. **测试问题**（逻辑对不对）→ `forge test`
4. **运行问题**（部署到链上对不对）→ `forge script` + `cast call`
5. **交互问题**（调用结果对不对）→ `cast call`

通常 80% 的问题在前两步就能解决。

### 进阶课常见问题优先排查(24~50 课)

对于进阶课(24~50)出现的问题,建议优先按以下分类排查:

1. **代理/升级问题**(44~48 课)→ `forge inspect <Logic> storage-layout` + `forge inspect <Logic> methods | grep upgrade`
2. **链下签名问题**(35~37 课)→ `cast call <addr> "DOMAIN_SEPARATOR()(bytes32)"` + `cast wallet sign` 离线签
3. **DeFi 数学问题**(39~43 课)→ `console.log` 中间值 + 校 decimals
4. **VRF/跨链问题**(49~50 课)→ 查 [vrf.chain.link](https://vrf.chain.link) / 跨链中继者日志