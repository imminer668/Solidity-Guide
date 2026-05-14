// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract EmergencyVault {
    address public owner;
    mapping(address => uint256) public balances;

    error NotOwner();
    error NothingToWithdraw();
    error WithdrawFailed();

    constructor() {
        owner = msg.sender;
    }

    receive() external payable {
        balances[msg.sender] += msg.value;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    // 紧急提取：owner 提取合约所有 ETH
    function emergencyWithdraw() external onlyOwner {
        if (address(this).balance == 0) revert NothingToWithdraw();
        uint256 amount = address(this).balance;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    // 用户提取自己的存款
    function withdraw() external {
        uint256 amount = balances[msg.sender];
        if (amount == 0) revert NothingToWithdraw();
        balances[msg.sender] = 0;
        (bool success, ) = payable(msg.sender).call{value: amount}("");
        if (!success) revert WithdrawFailed();
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
