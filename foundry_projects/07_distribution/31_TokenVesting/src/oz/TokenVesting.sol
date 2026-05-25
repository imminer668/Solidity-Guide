// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @dev OpenZeppelin 线性释放合约
 */
contract TokenVestingOZ {
    mapping(address => uint256) public erc20Released;
    address public immutable beneficiary;
    uint256 public immutable start;
    uint256 public immutable duration;

    event ERC20Released(address indexed token, uint256 amount);

    constructor(address beneficiaryAddress, uint256 durationSeconds) {
        require(beneficiaryAddress != address(0), "VestingWallet: beneficiary is zero address");
        beneficiary = beneficiaryAddress;
        start = block.timestamp;
        duration = durationSeconds;
    }

    function release(address token) public {
        uint256 releasable = vestedAmount(token, uint256(block.timestamp)) - erc20Released[token];
        require(releasable > 0, "No tokens to release");
        erc20Released[token] += releasable;
        emit ERC20Released(token, releasable);
        IERC20(token).transfer(beneficiary, releasable);
    }

    function vestedAmount(address token, uint256 timestamp) public view returns (uint256) {
        uint256 totalAllocation = IERC20(token).balanceOf(address(this)) + erc20Released[token];
        if (timestamp < start) {
            return 0;
        } else if (timestamp > start + duration) {
            return totalAllocation;
        } else {
            return (totalAllocation * (timestamp - start)) / duration;
        }
    }
}