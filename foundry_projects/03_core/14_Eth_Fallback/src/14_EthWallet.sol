// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EthWallet {
    address public owner;
    uint256 public balance;

    receive() external payable {
        balance += msg.value;
    }

    fallback() external payable {
        balance += msg.value;
    }

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function withdraw(uint256 amount) external onlyOwner {
        require(amount <= balance, "Insufficient balance");
        balance -= amount;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }

    function withdrawAll() external onlyOwner {
        uint256 amount = balance;
        balance = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Transfer failed");
    }
}
