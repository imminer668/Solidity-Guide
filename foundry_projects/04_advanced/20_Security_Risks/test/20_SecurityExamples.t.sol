// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/20_SecurityExamples.sol";

contract SecurityTest is Test {
    SafeVault public safeVault;

    function setUp() public {
        safeVault = new SafeVault();
    }

    function testDepositAndWithdraw() public {
        safeVault.deposit{value: 1 ether}();
        assertEq(safeVault.balances(address(this)), 1 ether);

        safeVault.withdraw(1 ether);
        assertEq(safeVault.balances(address(this)), 0);
    }

    function testMultipleWithdrawals() public {
        safeVault.deposit{value: 1 ether}();
        safeVault.withdraw(0.5 ether);
        safeVault.withdraw(0.5 ether);
        assertEq(safeVault.balances(address(this)), 0);
    }

    receive() external payable {}
}
