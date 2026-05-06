// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract DataLocation {
    uint256[] public arr;

    constructor() {
        arr.push(10);
        arr.push(20);
        arr.push(30);
    }

    function sumCalldata(uint256[] calldata _arr) external pure returns (uint256 total) {
        total = 0;
        for (uint256 i = 0; i < _arr.length; i++) {
            total += _arr[i];
        }
    }

    function doubleMemory(uint256[] memory _arr) external pure returns (uint256[] memory result) {
        result = new uint256[](_arr.length);
        for (uint256 i = 0; i < _arr.length; i++) {
            result[i] = _arr[i] * 2;
        }
    }
}
