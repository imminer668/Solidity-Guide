// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/19_TryCatch.sol";

contract TryCatchDemoTest is Test {
    TryCatchDemo public demo;
    TestContract public testContract;

    function setUp() public {
        demo = new TryCatchDemo();
    }

    function testCreateSuccess() public {
        (bool success, uint256 result) = demo.createContract(42);
        assertTrue(success);
        assertEq(result, 42);
    }

    function testCreateZeroReverts() public {
        (bool success, uint256 result) = demo.createContract(0);
        assertFalse(success);
        assertEq(result, 0);
    }

    function testCreateOnePanics() public {
        (bool success, uint256 result) = demo.createContract(1);
        assertFalse(success);
        assertEq(result, 0);
    }

    function testCallSuccess() public {
        testContract = new TestContract(10);
        bool ok = demo.callContract(address(testContract), 99);
        assertTrue(ok);
        assertEq(testContract.value(), 99);
    }

    function testCallZeroReverts() public {
        testContract = new TestContract(10);
        bool ok = demo.callContract(address(testContract), 0);
        assertFalse(ok);
        // value 保持原值 10
        assertEq(testContract.value(), 10);
    }
}
