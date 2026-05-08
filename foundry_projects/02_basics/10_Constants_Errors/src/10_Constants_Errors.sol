// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error InsufficientBalance();
error Unauthorized();
error ZeroAmount();

contract SimpleBank {
    // 常量
    uint256 public constant MIN_DEPOSIT = 0.001 ether;

    // 不可变变量
    address public immutable owner;

    // 状态变量
    mapping(address => uint256) public balance;

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        require(msg.value >= MIN_DEPOSIT, "Deposit too small");
        balance[msg.sender] += msg.value;
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) {
            revert ZeroAmount();
        }
        if (balance[msg.sender] < amount) {
            revert InsufficientBalance();
        }

        balance[msg.sender] -= amount;
        payable(msg.sender).transfer(amount);
    }

    function getBalance(address account) external view returns (uint256) {
        return balance[account];
    }
}
