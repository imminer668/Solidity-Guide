# 0xF1 Solidity 实战教程

> 给想入门 Web3 合约开发的人:从 0 写到 ERC20、NFT、Permit、DEX、闪电贷、代理升级和跨链桥。  
> **50 节课 / 11 个单元 / 50 个 Foundry 实战项目**,每一课都能 `forge test` 跑通。

如果你只看过 Solidity 语法,但不知道怎么真正写项目、测合约、理解协议,这套教程就是为你准备的。

这不是一份只讲概念的笔记,而是一套**边学边跑的 Solidity 实战路线**:每节课都有 `.md` 教程 + 独立 Foundry 项目,包含 `src/` 合约源码、`test/` 测试和项目说明。你可以按顺序从第 1 课学到第 50 课,也可以把它当作 Solidity 项目练习库反复刷。

学完之后,你应该能:

- 用 Foundry 完成合约编译、测试、脚本和本地运行闭环
- 手写 ERC20 / ERC721 / ERC1155 / WETH 等常见标准
- 理解 Merkle 空投、EIP-712、ERC20Permit、Multicall 等链下授权模式
- 写出 Dutch Auction、NFT Swap、ERC4626、DEX、Flashloan 等最小协议模型
- 看懂 Proxy、Transparent Proxy、UUPS、多签和跨链桥的核心设计
- 知道每类合约最容易踩的安全坑,不把教学 demo 误当生产代码

如果你觉得这套教程有用,可以先收藏 / Star,再从 [`navigation.md`](./navigation.md) 开始学习。

详细目录见 [`navigation.md`](./navigation.md),术语查询见 [`glossary.md`](./glossary.md),问题排查见 [`troubleshooting.md`](./troubleshooting.md)。

---

## 适合谁

- **Web3 新人**:想从零开始系统学 Solidity,不想只停留在语法层
- **前端工程师**:想知道钱包交互背后的合约到底怎么写、怎么测
- **传统后端工程师**:想理解 Solidity 与普通后端语言的关键差异
- **大学生 / 自学者**:想靠项目积累作品集,为实习、转岗、开源贡献做准备
- **已会 Solidity 基础的人**:想补齐"标准 + 协议 + 升级 + 跨链"完整知识图谱

**不适合**:已经有 3 年以上 Solidity 生产经验的人(本教程不涉及 Yield Farming 策略、MEV、Layer2 内部细节等高阶主题)。

---

## 为什么值得学

很多 Solidity 教程的问题是:前 10 节很清楚,后面就断了;或者只给代码,不告诉你为什么这么写。

这套教程重点解决 4 件事:

1. **有完整路线**:从开发环境、基础语法、合约能力,一路到标准协议、DeFi、升级和跨链。
2. **有可运行项目**:50 节课对应 50 个 Foundry 项目,不是只看文章。
3. **有 raw / oz 对照**:先手写看懂原理,再对照 OpenZeppelin 理解生产写法。
4. **有安全边界**:第 20 课集中讲安全,关键协议课再补"本课安全边界"。

你可以把它当作:

- Solidity 入门路线
- Foundry 练习项目集
- Web3 面试前的协议复习清单
- 学 ERC / DeFi / Proxy 的最小代码库

---

## 工具链

| 工具 | 版本 | 作用 |
|------|------|------|
| **Foundry** (`forge` / `cast` / `anvil`) | stable / nightly 都可 | 编译 / 测试 / 部署 / 链交互 |
| **Solidity** | v0.8.35 | 编译目标 |
| **OpenZeppelin Contracts** | v5.x(部分项目用) | 工业级实现参考 |

**安装 Foundry**(一次性):

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**进入任一项目**:

```bash
cd foundry_projects/02_basics/04_Source_File_Structure
forge build
forge test -vv
```

---

## 目录结构

```
0xF1/
├── README.md                       ← 本文件(入口)
├── navigation.md                   ← 50 课详细目录
├── glossary.md                     ← 统一术语表
├── troubleshooting.md              ← 高频问题排查
│
├── 01_Foundry/                     ← 单元 1(第 1~3 课,md 文件)
├── 02_basics/                      ← 单元 2(第 4~10 课)
├── 03_core/                        ← 单元 3(第 11~16 课)
├── 04_advanced/                    ← 单元 4(第 17~20 课)
├── 05_projects/                    ← 单元 5(第 21~23 课)
├── 06_standards/                   ← 单元 6(第 24~27 课)
├── 07_distribution/                ← 单元 7(第 28~33 课)
├── 08_offchain_auth/               ← 单元 8(第 34~38 课)
├── 09_protocols/                   ← 单元 9(第 39~43 课)
├── 10_upgrade_governance/          ← 单元 10(第 44~48 课)
├── 11_external_systems/            ← 单元 11(第 49~50 课)
│
└── foundry_projects/               ← 50 个实战项目(1:1 对应 50 课)
    ├── 01_Foundry/01_Why_Foundry/
    ├── 01_Foundry/02_Foundry_Setup/
    ├── 01_Foundry/03_First_Contract/
    ├── 02_basics/04_Source_File_Structure/
    ├── ...
    └── 11_external_systems/50_CrossChainBridge/
```

**1 课 = 1 个 .md 教程 + 1 个 foundry_projects 子项目**。子项目里有 `src/`(合约源码)、`test/`(测试)、`README.md`(项目说明)、`foundry.toml`、可能用到的 `lib/`(forge-std / openzeppelin-contracts 子模块)。

---

## 怎么学

### 推荐节奏(零基础)

| 阶段 | 课次 | 预计时间 | 重点 |
|------|------|---------|------|
| 入门 | 第 1~3 课 | 1~2 天 | 跑通 "写代码→编译→测试" 全流程 |
| 基础 | 第 4~10 课 | 3~5 天 | Solidity 语法 + Foundry 测试 |
| 核心 | 第 11~16 课 | 3~5 天 | 继承 / modifier / event / fallback / call / ABI |
| 安全与综合 | 第 17~23 课 | 4~6 天 | Create2 / 安全 / 三个综合项目 |
| 协议 | 第 24~43 课 | 10~15 天 | 标准代币 / 资金 / 签名 / DeFi 协议 |
| 升级 + 跨链 | 第 44~50 课 | 5~8 天 | 代理模式 / 多签 / 跨链桥 |

总计 **30~50 天**(每天 2~3 小时),完成本教程。

### 三条铁律

1. **每节课亲手敲代码**:不照抄也要改几行,改完再跑测试
2. **每节课跑通测试**:`forge test` 必须 0 failed 才算这节课通过
3. **遇到问题先查 [`troubleshooting.md`](./troubleshooting.md)**:80% 的问题别人踩过

### 学完之后怎么办

- **做课后练习**:每节末尾 2~3 个练习,做完一节等于练一个 mini 项目
- **回头做综合项目**:单元 5 的 Counter / SimpleBank / Voting 三个项目反复做
- **参与开源**:OZ、Uniswap V2/V3、Aave V3 的源码用本教程的工具链都能直接跑

---

## 教程特色

### 1. raw / oz 双实现,看清原理 vs 工业级

从第 6 课(函数)开始,涉及可对比实现的项目都给出**两套代码**:

- `src/raw/` —— 原生手写实现,看清单条赋值
- `src/oz/` —— 继承 OpenZeppelin,生产级实现参考

适用项目:ERC20、ERC721、ERC1155、WETH、MerkleTree、EIP-712、Permit、MultiCall、ERC4626、DEX、Flashloan、Proxy、UUPS、Bridge 等。

**学原理读 raw 版,要上线用 oz 版。**

### 2. "本课安全边界" 小节,把安全意识分散到每课

第 20 课是**集中**的安全讲解,本教程在以下 6 课又加了"本课安全边界"小节,把该课特有的安全坑**就地提醒**:

- 第 24 课 ERC20:mint 权限、approve 插队、USDT/FOT 陷阱
- 第 37 课 ERC20Permit:签名重放 / 跨链 / ecrecover 0 地址
- 第 42 课 DEX:三明治攻击 / 捐赠攻击 / 精度损失
- 第 43 课 Flashloan:回调重入 / 预言机操纵 / 白名单缺失
- 第 44 课 Proxy:存储槽错位 / constructor 不跑 / initialize 抢跑
- 第 50 课 CrossChainBridge:中继者单点 / mint 无上限 / 跨链重放

### 3. "扩展" 章节,选修内容

部分课在正文之后有"扩展"章节,讲清楚正式协议 / 进阶模式怎么写,不展开基础概念:

- 第 29 课 Airdrop 扩展:Merkle Tree claim 模式(配合第 34 课 MerkleTree)
- 后续会逐步补充更多扩展章节

---

## 配套文档

| 文档 | 用途 | 何时打开 |
|------|------|---------|
| [`navigation.md`](./navigation.md) | 50 课详细目录 + 实战代码链接 | 第一次打开本教程时 |
| [`glossary.md`](./glossary.md) | 术语统一表(EIP / opcode / DeFi 概念) | 遇到不认识的缩写 / 术语 |
| [`troubleshooting.md`](./troubleshooting.md) | 高频报错 + 排查步骤 | `forge test` 跑不通、ABI 不匹配、storage 错乱等 |

---

## 快速开始(30 秒跑通)

```bash
# 1. 安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# 2. 进入第一个项目
cd foundry_projects/01_Foundry/03_First_Contract

# 3. 编译 + 跑测试
forge build
forge test -vv
```

看到 `3 passed` 就是成功了。然后打开 `../../../01_Foundry/03_First_Contract.md` 读第一课。

---

## 已知边界与版本立场

### Cancun 硬分叉与 selfdestruct

`selfdestruct` 自 Cancun 升级(EIP-6780,2024-03 主网上线,Final)起**对已部署的合约不再有"删除"效果**,只会在"同一笔交易内 CREATE 的合约"上真正清空。教程第 18 课已按此口径讲解,生产合约中**不推荐**再把 selfdestruct 当作"删除合约"手段。EIP-4758(更激进的废弃方案)**目前是 Stagnant 状态,未被采纳**,不要混为一谈。

### 编译器版本 vs 链上行为

`--evm-version` 只决定**编译时可生成的指令集**,**链上行为由该链已激活的硬分叉决定**。教程代码默认目标 Solidity v0.8.35,在任何已激活 Cancun 的链(Ethereum / Arbitrum / Optimism / Base / Polygon 等)上跑,行为都按 Cancun 规则走。

### 教学 vs 生产

教程的"raw 实现"刻意**保留可读性**(如自写 ECDSA、自写 fallback assembly),**生产项目请用 OpenZeppelin / 行业标准库**,不要把 raw 版直接复制到主网。每节都明确点出"生产应该用 OZ 哪个库"。

### Foundry nightly

本教程使用 Foundry stable/nightly 都可跑通。如果你看到 `Warning: This is a nightly build of Foundry`,可以加 `FOUNDRY_DISABLE_NIGHTLY_WARNING=1` 关掉,不影响功能。

---

## 反馈

- 教程内容问题:在仓库提 issue,标 `[教程]` 前缀
- 代码问题:对应 `foundry_projects/<unit>/<lesson>/README.md` 提 issue,标 `[代码]` 前缀
- 跑不通 / 报错:先查 [`troubleshooting.md`](./troubleshooting.md),没找到再提 issue 并附 `forge --version` / `forge config` / 完整报错

---

## 版权

教程文字与项目代码采用 MIT 协议,欢迎二次创作,引用请保留来源。
