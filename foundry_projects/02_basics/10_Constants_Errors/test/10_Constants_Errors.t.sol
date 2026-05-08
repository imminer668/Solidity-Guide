// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/10_Constants_Errors.sol";

contract SimpleBankTest is Test {
    SimpleBank public bank;

    receive() external payable {}

    function setUp() public {
        bank = new SimpleBank();
    }

    function testDeposit() public {
        vm.deal(address(this), 1 ether);
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success);
        assertEq(bank.balance(address(this)), 1 ether);
    }

    function testWithdraw() public {
        vm.deal(address(this), 2 ether);
        (bool success,) = address(bank).call{value: 2 ether}("");
        require(success);
        bank.withdraw(1 ether);
        assertEq(bank.balance(address(this)), 1 ether);
    }

    function testZeroAmountRevert() public {
        vm.expectRevert(ZeroAmount.selector);
        bank.withdraw(0);
    }
}
