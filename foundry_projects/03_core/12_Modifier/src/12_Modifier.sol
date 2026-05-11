// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

error NotOwner();
error NotAdmin();

contract SecureContract {
    address public owner;
    mapping(address => bool) public admins;
    uint256 public storedValue;
    bool public paused;

    // ===== modifier =====
    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier onlyAdmin() {
        if (!admins[msg.sender]) revert NotAdmin();
        _;
    }

    modifier whenNotPaused() {
        if (paused) revert("Paused");
        _;
    }

    // ===== constructor =====
    constructor() {
        owner = msg.sender;
        admins[msg.sender] = true;
    }

    // ===== 管理函数 =====
    function addAdmin(address _addr) external onlyOwner {
        admins[_addr] = true;
    }

    function removeAdmin(address _addr) external onlyOwner {
        admins[_addr] = false;
    }

    function pause() external onlyOwner {
        paused = true;
    }

    // ===== 业务函数 =====
    function setValue(uint256 _value) external onlyAdmin whenNotPaused {
        storedValue = _value;
    }

    function getValue() external view returns (uint256) {
        return storedValue;
    }

    // owner 专属提款函数
    function withdrawAll() external onlyOwner {
        payable(owner).transfer(address(this).balance);
    }
}
