// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/14_EthWallet.sol";

contract EthWalletTest is Test {
    EthWallet public wallet;
    address owner = address(this);
    address recipient = address(0x1);

    receive() external payable {}

    function setUp() public {
        wallet = new EthWallet();
    }

    function testReceiveEth() public {
        (bool success,) = address(wallet).call{value: 1 ether}("");
        require(success);
        assertEq(wallet.balance(), 1 ether);
    }

    function testWithdraw() public {
        // 先存钱
        (bool success,) = address(wallet).call{value: 2 ether}("");
        require(success);

        // 再取钱
        wallet.withdraw(1 ether);
        assertEq(wallet.balance(), 1 ether);
    }

    function testOnlyOwnerCanWithdraw() public {
        (bool success,) = address(wallet).call{value: 1 ether}("");
        require(success);

        // 切换到非 owner
        vm.prank(recipient);
        vm.expectRevert("Not owner");
        wallet.withdraw(0.5 ether);
    }
}
