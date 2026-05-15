// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error Unauthorized();
error ReentrancyDetected();

// 有漏洞的合约（仅用于教学演示）
contract VulnerableVault {
    mapping(address => uint256) public balances;

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 有漏洞的 withdraw（先调用，后更新状态）
    function withdrawBuggy() external {
        uint256 balance = balances[msg.sender];
        require(balance > 0, "Zero balance");
        (bool success, ) = msg.sender.call{value: balance}("");
        require(success);
        balances[msg.sender] = 0; // 状态更新太晚！
    }
}

// 安全的合约
contract SafeVault {
    mapping(address => uint256) public balances;
    bool private locked;

    modifier noReentrancy() {
        require(!locked, "Reentrancy detected");
        locked = true;
        _;
        locked = false;
    }

    function deposit() external payable {
        balances[msg.sender] += msg.value;
    }

    // 安全的 withdraw（先更新状态）
    function withdraw(uint256 amount) external noReentrancy {
        require(balances[msg.sender] >= amount, "Insufficient balance");
        balances[msg.sender] -= amount; // 先更新状态
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
