// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/07_DataLocation.sol";

contract DataLocationTest is Test {
    DataLocation public dl;

    function setUp() public {
        dl = new DataLocation();
    }

    function testSumCalldata() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 10;
        arr[1] = 20;
        arr[2] = 30;
        assertEq(dl.sumCalldata(arr), 60);
    }

    function testDoubleMemory() public {
        uint256[] memory arr = new uint256[](2);
        arr[0] = 5;
        arr[1] = 15;
        uint256[] memory result = dl.doubleMemory(arr);
        assertEq(result[0], 10);
        assertEq(result[1], 30);
    }
}
