// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/06_Function.sol";

contract FunctionDemoTest is Test {
    FunctionDemo public demo;

    function setUp() public {
        demo = new FunctionDemo(10);
    }

    function testInitialValue() public {
        assertEq(demo.storedValue(), 10);
    }

    function testSetValue() public {
        demo.setStoredValue(99);
        assertEq(demo.storedValue(), 99);
    }

    function testGetValue() public {
        assertEq(demo.getStoredValue(), 10);
    }

    function testCalculate() public {
        (uint256 sum, uint256 product) = demo.calculate(3, 5);
        assertEq(sum, 8);
        assertEq(product, 15);
    }

    function testDoubleStoredValue() public {
        assertEq(demo.doubleStoredValue(), 20);
    }
}
