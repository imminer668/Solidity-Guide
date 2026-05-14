// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/18_EmergencyVault.sol";

contract EmergencyVaultTest is Test {
    EmergencyVault public vault;
    address owner = address(this);
    address user = address(0x1);

    receive() external payable {}

    function setUp() public {
        vault = new EmergencyVault();
    }

    function testDeposit() public {
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);
        assertEq(vault.getBalance(), 1 ether);
    }

    function testOwnerWithdraw() public {
        (bool success,) = address(vault).call{value: 2 ether}("");
        require(success);

        vault.emergencyWithdraw();
        assertEq(vault.getBalance(), 0);
    }

    function testUserWithdraw() public {
        vm.deal(user, 1 ether);
        vm.prank(user);
        (bool success,) = address(vault).call{value: 1 ether}("");
        require(success);

        vm.prank(user);
        vault.withdraw();
        assertEq(vault.getBalance(), 0);
    }
}
