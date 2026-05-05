// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract FunctionDemo {
    uint256 public storedValue;

    constructor(uint256 _initValue) {
        storedValue = _initValue;
    }

    function getStoredValue() external view returns (uint256) {
        return storedValue;
    }

    function setStoredValue(uint256 _value) external {
        storedValue = _value;
    }

    function calculate(uint256 a, uint256 b)
        external
        pure
        returns (uint256 sum, uint256 product)
    {
        sum = a + b;
        product = a * b;
    }

    function _double(uint256 _value) internal pure returns (uint256) {
        return _value * 2;
    }

    function doubleStoredValue() external view returns (uint256) {
        return _double(storedValue);
    }
}
