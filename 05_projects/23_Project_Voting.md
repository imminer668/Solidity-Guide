# 第 23 课：综合练习 3 — Voting 项目

## 1. 本节目标

学完这节课，你能：
- 实现一个完整的投票合约
- 掌握结构体和映射的组合使用
- 实现权限控制和事件记录
- 理解状态机的设计思路

## 2. 前置知识

- 第 8 课：数组、结构体与映射
- 第 11 课：继承、接口、库与 import
- 第 13 课：Event 与日志

## 3. 先讲结论

**Voting 项目展示了一个完整的"去中心化投票系统"，包含：**
- 候选人管理（添加、查询）
- 投票管理（一人一票、不可重复投）
- 权限控制（只有主席可以添加候选人）
- 事件记录（投票过程透明可查）

## 4. 合约设计

### Voting 合约规格

```solidity
// 数据结构
struct Candidate {
    string name;
    uint256 voteCount;
    bool exists;
}

// 核心状态
address public chairperson;            // 主席（部署者）
mapping(address => bool) public voters; // 已投票者
Candidate[] public candidates;        // 候选人列表
```

### 功能列表

| 函数 | 权限 | 功能 |
|------|------|------|
| `addCandidate(string)` | only chairperson | 添加候选人 |
| `vote(uint256)` | only registered voter | 给候选人投票 |
| `getCandidate(uint256)` | anyone | 获取候选人信息 |
| `getCandidateCount()` | anyone | 获取候选人数量 |

## 5. 代码拆解

### 完整合约

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

struct Candidate {
    string name;
    uint256 voteCount;
}

contract Voting {
    address public chairperson;
    mapping(address => bool) public voters;
    mapping(uint256 => bool) public votedForCandidate;
    Candidate[] public candidates;

    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCasted(address indexed voter, uint256 indexed candidateId);

    error AlreadyVoted();
    error InvalidCandidate();
    error NotChairperson();
    error AlreadyRegistered();

    constructor() {
        chairperson = msg.sender;
    }

    modifier onlyChairperson() {
        if (msg.sender != chairperson) revert NotChairperson();
        _;
    }

    // 添加候选人（主席操作）
    function addCandidate(string memory _name) external onlyChairperson {
        candidates.push(Candidate({name: _name, voteCount: 0}));
        emit CandidateAdded(candidates.length - 1, _name);
    }

    // 投票
    function vote(uint256 _candidateId) external {
        if (voters[msg.sender]) revert AlreadyVoted();
        if (_candidateId >= candidates.length) revert InvalidCandidate();

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit VoteCasted(msg.sender, _candidateId);
    }

    // 查询候选人
    function getCandidate(uint256 _id) external view returns (string memory name, uint256 voteCount) {
        if (_id >= candidates.length) revert InvalidCandidate();
        Candidate memory c = candidates[_id];
        return (c.name, c.voteCount);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }
}
```

## 6. 实操步骤

### 步骤 1：创建合约

```bash
cat > src/Voting.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

struct Candidate {
    string name;
    uint256 voteCount;
}

contract Voting {
    address public chairperson;
    mapping(address => bool) public voters;
    Candidate[] public candidates;

    event CandidateAdded(uint256 indexed candidateId, string name);
    event VoteCasted(address indexed voter, uint256 indexed candidateId);

    error AlreadyVoted();
    error InvalidCandidate();
    error NotChairperson();

    constructor() {
        chairperson = msg.sender;
    }

    modifier onlyChairperson() {
        if (msg.sender != chairperson) revert NotChairperson();
        _;
    }

    function addCandidate(string memory _name) external onlyChairperson {
        candidates.push(Candidate({name: _name, voteCount: 0}));
        emit CandidateAdded(candidates.length - 1, _name);
    }

    function vote(uint256 _candidateId) external {
        if (voters[msg.sender]) revert AlreadyVoted();
        if (_candidateId >= candidates.length) revert InvalidCandidate();

        voters[msg.sender] = true;
        candidates[_candidateId].voteCount++;
        emit VoteCasted(msg.sender, _candidateId);
    }

    function getCandidate(uint256 _id) external view returns (string memory name, uint256 voteCount) {
        if (_id >= candidates.length) revert InvalidCandidate();
        Candidate memory c = candidates[_id];
        return (c.name, c.voteCount);
    }

    function getCandidateCount() external view returns (uint256) {
        return candidates.length;
    }
}
EOF
```

### 步骤 2：编译

```bash
forge build
```

### 步骤 3：写测试

```bash
cat > test/Voting.t.sol << 'EOF'
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/Voting.sol";

contract VotingTest is Test {
    Voting public voting;
    address chairperson;
    address voter1 = address(0x1);
    address voter2 = address(0x2);
    address voter3 = address(0x3);

    function setUp() public {
        voting = new Voting();
        chairperson = address(this);
    }

    function testInitialState() public {
        assertEq(voting.getCandidateCount(), 0);
    }

    function testAddCandidate() public {
        voting.addCandidate("Alice");
        assertEq(voting.getCandidateCount(), 1);

        (string memory name, uint256 votes) = voting.getCandidate(0);
        assertEq(name, "Alice");
        assertEq(votes, 0);
    }

    function testAddMultipleCandidates() public {
        voting.addCandidate("Alice");
        voting.addCandidate("Bob");
        voting.addCandidate("Charlie");
        assertEq(voting.getCandidateCount(), 3);
    }

    function testVote() public {
        voting.addCandidate("Alice");
        voting.vote(0);
        (string memory name, uint256 votes) = voting.getCandidate(0);
        assertEq(votes, 1);
    }

    function testCannotVoteTwice() public {
        voting.addCandidate("Alice");
        voting.vote(0);
        vm.expectRevert(AlreadyVoted.selector);
        voting.vote(0);
    }

    function testMultipleVoters() public {
        voting.addCandidate("Alice");

        vm.prank(voter1);
        voting.vote(0);

        vm.prank(voter2);
        voting.vote(0);

        vm.prank(voter3);
        voting.vote(0);

        (, uint256 votes) = voting.getCandidate(0);
        assertEq(votes, 3);
    }

    function testInvalidCandidate() public {
        voting.addCandidate("Alice");
        vm.prank(voter1);
        vm.expectRevert(InvalidCandidate.selector);
        voting.vote(99);
    }

    function testOnlyChairpersonCanAdd() public {
        vm.prank(voter1);
        vm.expectRevert(NotChairperson.selector);
        voting.addCandidate("Bob");
    }
}
EOF
```

### 步骤 4：运行测试

```bash
forge test
```

## 7. 运行结果验证

- `forge build` 成功
- `forge test` 7 个测试全部 PASS

## 8. 常见错误排查

### 错误 1：投票时候选人 ID 超出范围

- **常见原因**：投票者传了超出 `candidates.length` 的索引
- **解决步骤**：在 `vote` 中检查 `require(_candidateId < candidates.length)`
- **验证方式**：`testInvalidCandidate` 测试已覆盖

### 错误 2：同一个选民投两次票

- **常见原因**：`voters[msg.sender]` 检查没有正确生效
- **解决步骤**：确认 `voters[msg.sender] = true` 在 vote 函数中正确设置
- **验证方式**：`testCannotVoteTwice` 测试已覆盖

### 错误 3：非 chairperson 添加候选人

- **常见原因**：`onlyChairperson` modifier 没有保护 `addCandidate`
- **解决步骤**：给 `addCandidate` 加上 `onlyChairperson`
- **验证方式**：`testOnlyChairpersonCanAdd` 测试已覆盖

## 9. 本节总结

- Voting 展示了结构体数组 + mapping 的组合使用
- 一人一票通过 `mapping(address => bool) public voters` 实现
- 主席权限通过 `onlyChairperson` modifier 控制
- 事件记录让投票过程透明可查
- `vm.prank()` 在 Foundry 测试中模拟不同用户调用

## 10. 课后练习

### 练习 1
在 Voting 合约中添加**代理投票**功能：
- `mapping(address => address) public delegates` — 记录每个选民的代理
- `function delegate(address _to) external` — 把投票权委托给另一个选民
- 代理可以再代理，形成投票权链条
- 但不能形成循环（如 A 代理 B，B 代理 A）

### 练习 2
在 Voting 合约中添加**权重投票**功能：
- `mapping(address => uint256) public weight` — 每个选民持有的代币数量（模拟）
- `function setWeight(address _voter, uint256 _weight) external onlyChairperson` — 设置选民权重
- 修改 `vote` 函数：投票时记录的不是 1 票，而是该选民的 weight
- 写测试验证：Alice 权重 3，Bob 权重 2，投同一个候选人后，该候选人 voteCount = 5