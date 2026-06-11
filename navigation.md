# 0xF1 Solidity 教程导航页

## 教程概述

本教程为零基础新手设计，零基础到进阶实战，系统化讲解 Solidity 开发。完成本教程后，你将具备独立开发、编译、测试、部署以太坊智能合约的能力。

**学习路径**：按课次顺序学习，从第 1 课到第 50 课，不要跳着学。

**基准版本**：Solidity v0.8.35 + Foundry 开发工具链

---

## 学习路径总览

| 阶段 | 单元 | 课次 | 核心内容 |
|------|------|------|---------|
| 入门 | [单元 1](#单元-1开发环境与第一个项目) | 第 1~3 课 | 开发环境与第一个项目 |
| 基础 | [单元 2](#单元-2solidity-基础语法) | 第 4~10 课 | Solidity 基础语法 |
| 进阶 | [单元 3](#单元-3合约开发核心能力) | 第 11~16 课 | 合约开发核心能力 |
| 深化 | [单元 4](#单元-4进阶机制与安全意识) | 第 17~20 课 | 进阶机制与安全意识 |
| 综合 | [单元 5](#单元-5综合练习与最小项目) | 第 21~23 课 | 综合练习与最小项目 |
| 协议 | [单元 6](#单元-6标准代币与-nft) | 第 24~27 课 | ERC20 / ERC721 / ERC1155 / WETH 标准实现 |
| 资金 | [单元 7](#单元-7资产分发与资金管理) | 第 28~33 课 | 空投 / 分账 / Vesting / Locker / Timelock / 治理 |
| 链下 | [单元 8](#单元-8链下授权白名单与调用优化) | 第 34~38 课 | Merkle Tree / 签名 / EIP-712 / Permit / MultiCall |
| 协议 | [单元 9](#单元-9市场机制与-defi-协议) | 第 39~43 课 | 荷兰式拍卖 / NFT Swap / ERC4626 / DEX / 闪电贷 |
| 升级 | [单元 10](#单元-10代理升级与治理控制) | 第 44~48 课 | Proxy / Upgrade / Transparent / UUPS / Multisig |
| 外部 | [单元 11](#单元-11外部系统与跨链扩展) | 第 49~50 课 | 链上随机数 / Chainlink VRF / 跨链桥 |

---

## 单元 1：开发环境与第一个项目

**目标**：打通"写代码→编译→测试→运行"本地闭环

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 1 课](./01_Foundry/01_Why_Foundry.md) | 为什么先学 Foundry | Foundry 是什么，为什么选它 | [项目](./foundry_projects/01_Foundry/01_Why_Foundry/) |
| [第 2 课](./01_Foundry/02_Foundry_Setup.md) | 安装 Foundry 与初始化项目 | forge/cast/anvil 安装，项目结构 | [项目](./foundry_projects/01_Foundry/02_Foundry_Setup/) |
| [第 3 课](./01_Foundry/03_First_Contract.md) | 写第一个合约并完成编译、测试、脚本运行 | HelloWeb3 + 全流程闭环 | [项目](./foundry_projects/01_Foundry/03_First_Contract/) |

**前置条件**：无（适合零基础）

---

## 单元 2：Solidity 基础语法

**目标**：建立 Solidity 最基础的语法认知

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 4 课](./02_basics/04_Source_File_Structure.md) | 源文件结构与合约组成 | SPDX / pragma / contract / 注释 | [项目](./foundry_projects/02_basics/04_Source_File_Structure/) |
| [第 5 课](./02_basics/05_Value_Types.md) | 值类型与默认值 | bool / int / uint / address / bytes / enum / 零值 | [项目](./foundry_projects/02_basics/05_Value_Types/) |
| [第 6 课](./02_basics/06_Function.md) | 函数：定义、返回值、可见性 | external / public / internal / private / return / 构造函数 | [项目](./foundry_projects/02_basics/06_Function/) |
| [第 7 课](./02_basics/07_Data_Location.md) | 数据存储位置 | storage / memory / calldata 的区别和使用场景 | [项目](./foundry_projects/02_basics/07_Data_Location/) |
| [第 8 课](./02_basics/08_Array_Struct.md) | 数组、结构体与映射 | 数组 / struct / mapping / 定长 vs 变长 | [项目](./foundry_projects/02_basics/08_Array_Struct/) |
| [第 9 课](./02_basics/09_Mapping.md) | 映射类型 mapping | mapping 键值对、默认值、嵌套 mapping | [项目](./foundry_projects/02_basics/09_Mapping/) |
| [第 10 课](./02_basics/10_Constants_Errors.md) | 常量与错误处理基础 | constant / immutable / require / revert / assert / 自定义 error | [项目](./foundry_projects/02_basics/10_Constants_Errors/) |

**前置条件**：第 1~3 课完成

---

## 单元 3：合约开发核心能力

**目标**：掌握合约开发中最常用的能力模块

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 11 课](./03_core/11_Inheritance_Interface_Library.md) | 继承、接口、库与 import | is / interface / library / import / override | [项目](./foundry_projects/03_core/11_Inheritance_Interface_Library/) |
| [第 12 课](./03_core/12_Modifier.md) | Modifier 与权限控制 | modifier 定义 / onlyOwner / whenPaused / vm.prank | [项目](./foundry_projects/03_core/12_Modifier/) |
| [第 13 课](./03_core/13_Event.md) | Event 与日志 | event 定义 / emit / indexed / vm.expectEmit | [项目](./foundry_projects/03_core/13_Event/) |
| [第 14 课](./03_core/14_Eth_Fallback.md) | ETH 收发与 fallback | receive() / fallback() / .call{value:} / transfer vs call | [项目](./foundry_projects/03_core/14_Eth_Fallback/) |
| [第 15 课](./03_core/15_Call_Delegatecall.md) | 合约调用：Call 与 Delegatecall | call / delegatecall / ABI 编码 / 上下文 | [项目](./foundry_projects/03_core/15_Call_Delegatecall/) |
| [第 16 课](./03_core/16_ABI_Selector.md) | ABI 编解码与 Selector | abi.encode / abi.decode / selector / encodeWithSignature | [项目](./foundry_projects/03_core/16_ABI_Selector/) |

**前置条件**：单元 2 完成

---

## 单元 4：进阶机制与安全意识

**目标**：知道哪些内容能用、有什么风险、如何理解

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 17 课](./04_advanced/17_Create_Create2.md) | Create 与 Create2 | new / Create2 / salt / 可预知地址 | [项目](./foundry_projects/04_advanced/17_Create_Create2/) |
| [第 18 课](./04_advanced/18_Delete_Contract.md) | 删除合约与 selfdestruct | selfdestruct / EIP-4758,EIP-6780 限制 / 替代方案 | [项目](./foundry_projects/04_advanced/18_Delete_Contract/) |
| [第 19 课](./04_advanced/19_TryCatch.md) | Try-Catch 与异常处理 | try-catch / Panic vs Error / 捕获外部调用异常 | [项目](./foundry_projects/04_advanced/19_TryCatch/) |
| [第 20 课](./04_advanced/20_Security_Risks.md) | 常见安全问题与风险提醒 | 重入攻击 / CEI 模式 / ReentrancyGuard / 未检查返回值 | [项目](./foundry_projects/04_advanced/20_Security_Risks/) |

**前置条件**：单元 3 完成

---

## 单元 5：综合练习与最小项目

**目标**：把前面学的内容组合起来

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 21 课](./05_projects/21_Project_Counter.md) | 综合练习 1：Counter 项目 | Forge 项目结构 / public getter / modifier / 测试 | [项目](./foundry_projects/05_projects/21_Project_Counter/) |
| [第 22 课](./05_projects/22_Project_SimpleBank.md) | 综合练习 2：SimpleBank 项目 | 余额管理 / 存取 ETH / 重入防护 | [项目](./foundry_projects/05_projects/22_Project_SimpleBank/) |
| [第 23 课](./05_projects/23_Project_Voting.md) | 综合练习 3：Voting 项目 | 结构体数组 / 一人一票 / 事件记录 | [项目](./foundry_projects/05_projects/23_Project_Voting/) |

**前置条件**：单元 2 和单元 3 完成

---

## 单元 6：标准代币与 NFT

**目标**：手写实现 ERC20 / ERC721 / ERC1155 / WETH 四个最常用的代币标准,理解 OpenZeppelin 工业级实现的差异

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 24 课](./06_standards/24_ERC20.md) | ERC20 同质化代币 | IERC20 接口 / transfer/approve/transferFrom / mint/burn | [项目](./foundry_projects/06_standards/24_ERC20/) |
| [第 25 课](./06_standards/25_ERC721.md) | ERC721 非同质化代币 (NFT) | tokenId / ownerOf / tokenURI / 铸造与转移 | [项目](./foundry_projects/06_standards/25_ERC721/) |
| [第 26 课](./06_standards/26_ERC1155.md) | ERC1155 多资产混合 | 一次交易管理多代币 / batch mint / gas 优化 | [项目](./foundry_projects/06_standards/26_ERC1155/) |
| [第 27 课](./06_standards/27_WETH.md) | WETH 包装以太币 | deposit/withdraw / 1:1 锚定 / 与 ERC20 协议互通 | [项目](./foundry_projects/06_standards/27_WETH/) |

**前置条件**：单元 5 完成(熟悉 Foundry 测试 + 部署)

---

## 单元 7：资产分发与资金管理

**目标**：掌握项目方在生态运营中常用的 6 个资金管理合约(空投/分账/线性释放/锁仓/时间锁/治理)

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 28 课](./07_distribution/28_Faucet.md) | Faucet 水龙头 | time-lock 防刷 / cooldown 限制 / 直接转账 | [项目](./foundry_projects/07_distribution/28_Faucet/) |
| [第 29 课](./07_distribution/29_Airdrop.md) | Airdrop 空投 | Merkle Tree 链下白名单 + claim 链上验证 | [项目](./foundry_projects/07_distribution/29_Airdrop/) |
| [第 30 课](./07_distribution/30_PaymentSplit.md) | PaymentSplit 分账 | 多受益人按比例分账 / 释放机制 | [项目](./foundry_projects/07_distribution/30_PaymentSplit/) |
| [第 31 课](./07_distribution/31_TokenVesting.md) | TokenVesting 线性释放 | cliff 期 / 线性释放 / 可撤销/不可撤销 | [项目](./foundry_projects/07_distribution/31_TokenVesting/) |
| [第 32 课](./07_distribution/32_TokenLocker.md) | TokenLocker 锁仓 | 锁定代币到期才能取 / 公平发射必备 | [项目](./foundry_projects/07_distribution/32_TokenLocker/) |
| [第 33 课](./07_distribution/33_Timelock.md) | Timelock + Governor | 关键操作延迟执行 / 治理提案 + 投票 | [项目](./foundry_projects/07_distribution/33_Timelock/) |

**前置条件**：单元 6 + 单元 8(链下签名)

---

## 单元 8：链下授权、白名单与调用优化

**目标**：用链下签名 + Merkle 证明降低 gas,用 MultiCall 提升交互效率

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 34 课](./08_offchain_auth/34_MerkleTree.md) | MerkleTree 白名单 | O(log n) 验证 / 链下存储 / 节省 gas | [项目](./foundry_projects/08_offchain_auth/34_MerkleTree/) |
| [第 35 课](./08_offchain_auth/35_Signature.md) | ECDSA 数字签名 | ecrecover / 私钥签名 / 链上验证身份 | [项目](./foundry_projects/08_offchain_auth/35_Signature/) |
| [第 36 课](./08_offchain_auth/36_EIP712.md) | EIP-712 类型化签名 | 人类可读结构 / 防盲签 / Permit/EIP-2612 | [项目](./foundry_projects/08_offchain_auth/36_EIP712/) |
| [第 37 课](./08_offchain_auth/37_ERC20Permit.md) | ERC20Permit 无 approve 转账 | 链下签名 + 链上一次交易 | [项目](./foundry_projects/08_offchain_auth/37_ERC20Permit/) |
| [第 38 课](./08_offchain_auth/38_MultiCall.md) | MultiCall 批量调用 | atomic batch / 降低 gas / 跨合约读状态 | [项目](./foundry_projects/08_offchain_auth/38_MultiCall/) |

**前置条件**：单元 3 的合约调用 + 单元 6 的 ERC20

---

## 单元 9：市场机制与 DeFi 协议

**目标**：手写 5 个最经典的 DeFi 协议(拍卖/交换/金库/AMM/闪电贷),理解 DeFi 协议的设计范式

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 39 课](./09_protocols/39_DutchAuction.md) | DutchAuction 荷兰式拍卖 | 价格随时间下降 / NFT 公平发射 | [项目](./foundry_projects/09_protocols/39_DutchAuction/) |
| [第 40 课](./09_protocols/40_NFTSwap.md) | NFTSwap NFT 交换 | ERC721 ↔ ERC20 撮合 / 订单匹配 | [项目](./foundry_projects/09_protocols/40_NFTSwap/) |
| [第 41 课](./09_protocols/41_ERC4626.md) | ERC4626 代币化金库 | deposit/mint/withdraw/redeem / share 概念 | [项目](./foundry_projects/09_protocols/41_ERC4626/) |
| [第 42 课](./09_protocols/42_DEX.md) | DEX 去中心化交易所 | Constant Product (x*y=k) / LP Token / 滑点 | [项目](./foundry_projects/09_protocols/42_DEX/) |
| [第 43 课](./09_protocols/43_Flashloan.md) | Flashloan 闪电贷 | 0 抵押借款 / 单笔交易原子性 / 套利 | [项目](./foundry_projects/09_protocols/43_Flashloan/) |

**前置条件**：单元 6 + 单元 8(签名)

---

## 单元 10：代理升级与治理控制

**目标**：理解 4 种代理模式 + 多签钱包,为生产级 DeFi 协议铺路

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 44 课](./10_upgrade_governance/44_ProxyContract.md) | Proxy 基础 | delegatecall 语义 / fallback 路由 / storage | [项目](./foundry_projects/10_upgrade_governance/44_ProxyContract/) |
| [第 45 课](./10_upgrade_governance/45_Upgrade.md) | Upgrade 可升级 | 切换 implementation / 存储保持 | [项目](./foundry_projects/10_upgrade_governance/45_Upgrade/) |
| [第 46 课](./10_upgrade_governance/46_TransparentProxy.md) | TransparentProxy 透明代理 | admin 路径隔离 / 防选择器冲突 | [项目](./foundry_projects/10_upgrade_governance/46_TransparentProxy/) |
| [第 47 课](./10_upgrade_governance/47_UUPS.md) | UUPS 通用可升级标准 | EIP-1822 / upgrade 在 Logic / OZ `_authorizeUpgrade` | [项目](./foundry_projects/10_upgrade_governance/47_UUPS/) |
| [第 48 课](./10_upgrade_governance/48_MultisigWallet.md) | MultisigWallet 多签 | M-of-N 签名 / 升序拼接 / nonce + chainid 防重放 | [项目](./foundry_projects/10_upgrade_governance/48_MultisigWallet/) |

**前置条件**：单元 3 的合约调用 + 单元 5 的 Foundry 测试

---

## 单元 11：外部系统与跨链扩展

**目标**：理解链上与链下 / 链 A 与链 B 之间的桥接模式

| 课次 | 标题 | 核心内容 | 实战代码 |
|------|------|---------|---------|
| [第 49 课](./11_external_systems/49_Random.md) | 链上随机数与 Chainlink VRF | 链上伪随机的不安全性 / VRF 流程 | [项目](./foundry_projects/11_external_systems/49_Random/) |
| [第 50 课](./11_external_systems/50_CrossChainBridge.md) | CrossChainBridge 跨链桥 | burn/mint 模式 / lock/unlock 模式 / 中继者风险 | [项目](./foundry_projects/11_external_systems/50_CrossChainBridge/) |

**前置条件**：单元 6 + 单元 8(签名)

---

## 附录

### 核心资源（必读）

| 资源 | 文件 | 说明 |
|------|------|------|
| [术语表](./glossary.md) | `glossary.md` | 全教程统一术语解释，查不认识的词 |
| [排障手册](./troubleshooting.md) | `troubleshooting.md` | 按问题类型分类的高频问题解决方案 |

### 工具速查

| 命令 | 作用 |
|------|------|
| `forge --version` | 查看 Foundry 版本 |
| `forge build` | 编译合约 |
| `forge test` | 运行测试 |
| `forge script` | 运行部署脚本 |
| `cast call` | 调用合约（只读） |
| `cast send` | 调用合约（写入链） |
| `anvil` | 启动本地测试链 |

---

## 学习建议

### 第一遍学习（按顺序）
1. 从第 1 课开始，按顺序读，不要跳课
2. 每节课**亲手敲代码**，不要只看不写
3. 每节课**跑通测试**，不要只编译
4. 遇到问题查[排障手册](./troubleshooting.md)，搜不到再问

### 第二遍复习（按需要）
- 需要查某个知识点时，用导航页定位到对应章节
- 需要练手时，做每节课的课后练习
- 需要深入理解时，做单元 5 的三个综合项目

### 常见问题
- **看不懂代码**：先跳过，往后学到更多例子再回头看
- **跑不通测试**：查看 [排障手册](./troubleshooting.md)，或检查 foundry 是否正确安装
- **不知道某术语**：查看 [术语表](./glossary.md)
- **代码报错**：看报错信息的文件和行号，通常是分号/括号不匹配

---

## 上下课跳转

### 单元 1：开发环境

- [第 1 课：为什么先学 Foundry](./01_Foundry/01_Why_Foundry.md)
- [第 2 课：安装 Foundry 与初始化项目](./01_Foundry/02_Foundry_Setup.md) ← 上一课 | [下一课：第 3 课](./01_Foundry/03_First_Contract.md)
- [第 3 课：写第一个合约](./01_Foundry/03_First_Contract.md) ← [上一课：第 2 课](./01_Foundry/02_Foundry_Setup.md) | [下一课：第 4 课](./02_basics/04_Source_File_Structure.md)

### 单元 2：基础语法

- [第 4 课：源文件结构](./02_basics/04_Source_File_Structure.md) ← [上一课：第 3 课](./01_Foundry/03_First_Contract.md) | [下一课：第 5 课](./02_basics/05_Value_Types.md)
- [第 5 课：值类型与默认值](./02_basics/05_Value_Types.md) ← 上一课 | [下一课：第 6 课](./02_basics/06_Function.md)
- [第 6 课：函数](./02_basics/06_Function.md) ← 上一课 | [下一课：第 7 课](./02_basics/07_Data_Location.md)
- [第 7 课：数据存储位置](./02_basics/07_Data_Location.md) ← 上一课 | [下一课：第 8 课](./02_basics/08_Array_Struct.md)
- [第 8 课：数组、结构体与映射](./02_basics/08_Array_Struct.md) ← 上一课 | [下一课：第 9 课](./02_basics/09_Mapping.md)
- [第 9 课：映射类型 mapping](./02_basics/09_Mapping.md) ← 上一课 | [下一课：第 10 课](./02_basics/10_Constants_Errors.md)
- [第 10 课：常量与错误处理基础](./02_basics/10_Constants_Errors.md) ← 上一课 | [下一课：第 11 课](./03_core/11_Inheritance_Interface_Library.md)

### 单元 3：核心能力

- [第 11 课：继承、接口、库与 import](./03_core/11_Inheritance_Interface_Library.md) ← [上一课：第 10 课](./02_basics/10_Constants_Errors.md) | [下一课：第 12 课](./03_core/12_Modifier.md)
- [第 12 课：Modifier 与权限控制](./03_core/12_Modifier.md) ← 上一课 | [下一课：第 13 课](./03_core/13_Event.md)
- [第 13 课：Event 与日志](./03_core/13_Event.md) ← 上一课 | [下一课：第 14 课](./03_core/14_Eth_Fallback.md)
- [第 14 课：ETH 收发与 fallback](./03_core/14_Eth_Fallback.md) ← 上一课 | [下一课：第 15 课](./03_core/15_Call_Delegatecall.md)
- [第 15 课：合约调用：Call 与 Delegatecall](./03_core/15_Call_Delegatecall.md) ← 上一课 | [下一课：第 16 课](./03_core/16_ABI_Selector.md)
- [第 16 课：ABI 编解码与 Selector](./03_core/16_ABI_Selector.md) ← 上一课 | [下一课：第 17 课](./04_advanced/17_Create_Create2.md)

### 单元 4：进阶

- [第 17 课：Create 与 Create2](./04_advanced/17_Create_Create2.md) ← [上一课：第 16 课](./03_core/16_ABI_Selector.md) | [下一课：第 18 课](./04_advanced/18_Delete_Contract.md)
- [第 18 课：删除合约与 selfdestruct](./04_advanced/18_Delete_Contract.md) ← 上一课 | [下一课：第 19 课](./04_advanced/19_TryCatch.md)
- [第 19 课：Try-Catch 与异常处理](./04_advanced/19_TryCatch.md) ← 上一课 | [下一课：第 20 课](./04_advanced/20_Security_Risks.md)
- [第 20 课：常见安全问题与风险提醒](./04_advanced/20_Security_Risks.md) ← 上一课 | [下一课：第 21 课](./05_projects/21_Project_Counter.md)

### 单元 5：综合项目

- [第 21 课：Counter 项目](./05_projects/21_Project_Counter.md) ← [上一课：第 20 课](./04_advanced/20_Security_Risks.md) | [下一课：第 22 课](./05_projects/22_Project_SimpleBank.md)
- [第 22 课：SimpleBank 项目](./05_projects/22_Project_SimpleBank.md) ← 上一课 | [下一课：第 23 课](./05_projects/23_Project_Voting.md)
- [第 23 课：Voting 项目](./05_projects/23_Project_Voting.md) ← [上一课：第 22 课](./05_projects/22_Project_SimpleBank.md) | [下一课：第 24 课](./06_standards/24_ERC20.md)

### 单元 6：标准代币与 NFT

- [第 24 课：ERC20 同质化代币](./06_standards/24_ERC20.md) ← [上一课：第 23 课](./05_projects/23_Project_Voting.md) | [下一课：第 25 课](./06_standards/25_ERC721.md)
- [第 25 课：ERC721 非同质化代币 (NFT)](./06_standards/25_ERC721.md) ← 上一课 | [下一课：第 26 课](./06_standards/26_ERC1155.md)
- [第 26 课：ERC1155 多资产混合](./06_standards/26_ERC1155.md) ← 上一课 | [下一课：第 27 课](./06_standards/27_WETH.md)
- [第 27 课：WETH 包装以太币](./06_standards/27_WETH.md) ← 上一课 | [下一课：第 28 课](./07_distribution/28_Faucet.md)

### 单元 7：资产分发与资金管理

- [第 28 课：Faucet 水龙头](./07_distribution/28_Faucet.md) ← [上一课：第 27 课](./06_standards/27_WETH.md) | [下一课：第 29 课](./07_distribution/29_Airdrop.md)
- [第 29 课：Airdrop 空投](./07_distribution/29_Airdrop.md) ← 上一课 | [下一课：第 30 课](./07_distribution/30_PaymentSplit.md)
- [第 30 课：PaymentSplit 分账](./07_distribution/30_PaymentSplit.md) ← 上一课 | [下一课：第 31 课](./07_distribution/31_TokenVesting.md)
- [第 31 课：TokenVesting 线性释放](./07_distribution/31_TokenVesting.md) ← 上一课 | [下一课：第 32 课](./07_distribution/32_TokenLocker.md)
- [第 32 课：TokenLocker 锁仓](./07_distribution/32_TokenLocker.md) ← 上一课 | [下一课：第 33 课](./07_distribution/33_Timelock.md)
- [第 33 课：Timelock + Governor](./07_distribution/33_Timelock.md) ← 上一课 | [下一课：第 34 课](./08_offchain_auth/34_MerkleTree.md)

### 单元 8：链下授权、白名单与调用优化

- [第 34 课：MerkleTree 白名单](./08_offchain_auth/34_MerkleTree.md) ← [上一课：第 33 课](./07_distribution/33_Timelock.md) | [下一课：第 35 课](./08_offchain_auth/35_Signature.md)
- [第 35 课：ECDSA 数字签名](./08_offchain_auth/35_Signature.md) ← 上一课 | [下一课：第 36 课](./08_offchain_auth/36_EIP712.md)
- [第 36 课：EIP-712 类型化签名](./08_offchain_auth/36_EIP712.md) ← 上一课 | [下一课：第 37 课](./08_offchain_auth/37_ERC20Permit.md)
- [第 37 课：ERC20Permit 无 approve 转账](./08_offchain_auth/37_ERC20Permit.md) ← 上一课 | [下一课：第 38 课](./08_offchain_auth/38_MultiCall.md)
- [第 38 课：MultiCall 批量调用](./08_offchain_auth/38_MultiCall.md) ← 上一课 | [下一课：第 39 课](./09_protocols/39_DutchAuction.md)

### 单元 9：市场机制与 DeFi 协议

- [第 39 课：DutchAuction 荷兰式拍卖](./09_protocols/39_DutchAuction.md) ← [上一课：第 38 课](./08_offchain_auth/38_MultiCall.md) | [下一课：第 40 课](./09_protocols/40_NFTSwap.md)
- [第 40 课：NFTSwap NFT 交换](./09_protocols/40_NFTSwap.md) ← 上一课 | [下一课：第 41 课](./09_protocols/41_ERC4626.md)
- [第 41 课：ERC4626 代币化金库](./09_protocols/41_ERC4626.md) ← 上一课 | [下一课：第 42 课](./09_protocols/42_DEX.md)
- [第 42 课：DEX 去中心化交易所](./09_protocols/42_DEX.md) ← 上一课 | [下一课：第 43 课](./09_protocols/43_Flashloan.md)
- [第 43 课：Flashloan 闪电贷](./09_protocols/43_Flashloan.md) ← 上一课 | [下一课：第 44 课](./10_upgrade_governance/44_ProxyContract.md)

### 单元 10：代理升级与治理控制

- [第 44 课：Proxy 基础](./10_upgrade_governance/44_ProxyContract.md) ← [上一课：第 43 课](./09_protocols/43_Flashloan.md) | [下一课：第 45 课](./10_upgrade_governance/45_Upgrade.md)
- [第 45 课：Upgrade 可升级](./10_upgrade_governance/45_Upgrade.md) ← 上一课 | [下一课：第 46 课](./10_upgrade_governance/46_TransparentProxy.md)
- [第 46 课：TransparentProxy 透明代理](./10_upgrade_governance/46_TransparentProxy.md) ← 上一课 | [下一课：第 47 课](./10_upgrade_governance/47_UUPS.md)
- [第 47 课：UUPS 通用可升级标准](./10_upgrade_governance/47_UUPS.md) ← 上一课 | [下一课：第 48 课](./10_upgrade_governance/48_MultisigWallet.md)
- [第 48 课：MultisigWallet 多签](./10_upgrade_governance/48_MultisigWallet.md) ← 上一课 | [下一课：第 49 课](./11_external_systems/49_Random.md)

### 单元 11：外部系统与跨链扩展

- [第 49 课：链上随机数与 Chainlink VRF](./11_external_systems/49_Random.md) ← [上一课：第 48 课](./10_upgrade_governance/48_MultisigWallet.md) | [下一课：第 50 课](./11_external_systems/50_CrossChainBridge.md)
- [第 50 课：CrossChainBridge 跨链桥](./11_external_systems/50_CrossChainBridge.md) ← [上一课：第 49 课](./11_external_systems/49_Random.md)