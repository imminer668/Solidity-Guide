// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract HelloWeb3 {
    // 公开的字符串状态变量，存储欢迎语
    string public greeting = "Hello Web3!";

    // 获取当前欢迎语
    function getGreeting() external view returns (string memory) {
        return greeting;
    }
}
