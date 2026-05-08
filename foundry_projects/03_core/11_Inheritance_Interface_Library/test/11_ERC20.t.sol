// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/11_ERC20.sol";

contract ERC20Test is Test {
    SimpleERC20 public token;

    function setUp() public {
        token = new SimpleERC20("MyToken", "MTK");
    }

    function testMintAndBalance() public {
        token.mint(address(this), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testTransfer() public {
        token.mint(address(this), 1000);
        token.transfer(address(0x1), 300);
        assertEq(token.balanceOf(address(this)), 700);
        assertEq(token.balanceOf(address(0x1)), 300);
    }
}
