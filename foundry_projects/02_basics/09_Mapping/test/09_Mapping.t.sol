// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/09_Mapping.sol";

contract MappingDemoTest is Test {
    MappingDemo public demo;
    address public user1 = address(0x1);
    address public user2 = address(0x2);

    function setUp() public {
        demo = new MappingDemo();
    }

    function testInitialBalance() public {
        assertEq(demo.getBalance(user1), 0);
    }

    function testDeposit() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        demo.deposit{value: 1 ether}();
        assertEq(demo.getBalance(user1), 1 ether);
    }

    function testWithdraw() public {
        vm.deal(user1, 2 ether);
        vm.prank(user1);
        demo.deposit{value: 2 ether}();
        // 再取
        vm.prank(user1);
        demo.withdraw(1 ether);
        assertEq(demo.getBalance(user1), 1 ether);
    }

    function testDefaultMappingValue() public {
        // 从未操作过的地址，默认返回 0
        assertEq(demo.getBalance(address(0x999)), 0);
    }
}
