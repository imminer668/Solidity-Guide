// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/04_MinimalContract.sol";

contract MinimalContractTest is Test {
    MinimalContract public contract_;

    function setUp() public {
        contract_ = new MinimalContract(100);
    }

    function testInitialNumber() public {
        assertEq(contract_.number(), 100);
    }

    function testGetNumber() public {
        assertEq(contract_.getNumber(), 100);
    }
}
