// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ValueTypesDemo {
    bool public flag = true;
    int public negative = -10;
    uint public positive = 100;
    address public owner = msg.sender;
    bytes32 public data = "Hello";
    enum OrderStatus { Pending, Confirmed, Shipped }
    OrderStatus public status = OrderStatus.Pending;

    // 默认值
    bool public defaultBool;
    uint256 public defaultUint;

    function getStatusValue() external view returns (uint) {
        return uint(status);
    }
}
