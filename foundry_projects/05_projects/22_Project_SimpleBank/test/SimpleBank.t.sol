// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/SimpleBank.sol";

contract SimpleBankTest is Test {
    SimpleBank public bank;
    address user1 = address(0x1);
    address user2 = address(0x2);

    function setUp() public {
        bank = new SimpleBank();
    }

    function testInitialBalance() public {
        assertEq(bank.balances(user1), 0);
        assertEq(bank.getContractBalance(), 0);
    }

    function testDeposit() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.getContractBalance(), 1 ether);
    }

    function testDirectTransfer() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success);
        assertEq(bank.balances(user1), 2 ether);
    }

    function testWithdraw() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        vm.prank(user1);
        bank.withdraw(0.5 ether);

        assertEq(bank.balances(user1), 0.5 ether);
    }

    function testWithdrawInsufficient() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        bank.deposit{value: 1 ether}();

        vm.prank(user1);
        vm.expectRevert(InsufficientBalance.selector);
        bank.withdraw(2 ether);
    }

    function testZeroDepositRevert() public {
        vm.deal(user1, 10 ether);
        vm.prank(user1);
        vm.expectRevert(ZeroAmount.selector);
        bank.deposit{value: 0}();
    }

    function testZeroWithdrawRevert() public {
        vm.prank(user1);
        vm.expectRevert(ZeroAmount.selector);
        bank.withdraw(0);
    }

    function testMultipleUsers() public {
        vm.deal(user1, 10 ether);
        vm.deal(user2, 10 ether);

        vm.prank(user1);
        bank.deposit{value: 1 ether}();
        vm.prank(user2);
        bank.deposit{value: 2 ether}();

        assertEq(bank.balances(user1), 1 ether);
        assertEq(bank.balances(user2), 2 ether);
        assertEq(bank.getContractBalance(), 3 ether);
    }
}