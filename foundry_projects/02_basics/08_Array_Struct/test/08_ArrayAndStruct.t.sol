// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/08_ArrayAndStruct.sol";

contract ArrayAndStructTest is Test {
    ArrayAndStruct public contract_;

    function setUp() public {
        contract_ = new ArrayAndStruct();
    }

    // 数组测试
    function testPushAndGetLength() public {
        contract_.pushNumber(10);
        contract_.pushNumber(20);
        assertEq(contract_.getLength(), 2);
    }

    function testPop() public {
        contract_.pushNumber(10);
        contract_.pushNumber(20);
        contract_.popNumber();
        assertEq(contract_.getLength(), 1);
    }

    // 结构体测试
    function testAddStudent() public {
        contract_.addStudent("Alice", 95);
        (, uint256 score, bool isActive) = contract_.students(0);
        assertEq(score, 95);
        assertEq(isActive, true);
    }

    function testUpdateScore() public {
        contract_.addStudent("Bob", 80);
        contract_.updateScore(0, 99);
        (, uint256 newScore, ) = contract_.students(0);
        assertEq(newScore, 99);
    }
}
