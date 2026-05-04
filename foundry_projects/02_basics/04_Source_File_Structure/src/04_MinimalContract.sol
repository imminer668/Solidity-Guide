// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

// 第 4 课演示：源文件结构
contract MinimalContract {
    uint256 public number;

    constructor(uint256 initNumber) {
        number = initNumber;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
