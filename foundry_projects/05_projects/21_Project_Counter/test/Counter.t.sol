// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/Counter.sol";

contract CounterTest is Test {
    Counter public counter;
    address owner = address(this);

    function setUp() public {
        counter = new Counter();
    }

    function testInitialCount() public {
        assertEq(counter.count(), 0);
    }

    function testInitialOwner() public {
        assertEq(counter.owner(), owner);
    }

    function testIncrement() public {
        counter.increment();
        assertEq(counter.count(), 1);
    }

    function testMultipleIncrement() public {
        counter.increment();
        counter.increment();
        counter.increment();
        assertEq(counter.count(), 3);
    }

    function testDecrement() public {
        counter.increment();
        counter.increment();
        vm.prank(owner);
        counter.decrement();
        assertEq(counter.count(), 1);
    }

    function testDecrementAtZero() public {
        vm.prank(owner);
        vm.expectRevert("Count is zero");
        counter.decrement();
    }

    function testReset() public {
        counter.increment();
        counter.increment();
        vm.prank(owner);
        counter.reset();
        assertEq(counter.count(), 0);
    }

    function testNonOwnerCannotDecrement() public {
        counter.increment();
        address stranger = address(0x1);
        vm.prank(stranger);
        vm.expectRevert("Not owner");
        counter.decrement();
    }

    function testNonOwnerCannotReset() public {
        address stranger = address(0x1);
        vm.prank(stranger);
        vm.expectRevert("Not owner");
        counter.reset();
    }
}