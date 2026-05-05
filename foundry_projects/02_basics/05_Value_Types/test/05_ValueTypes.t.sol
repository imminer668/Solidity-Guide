// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/05_ValueTypes.sol";

contract ValueTypesDemoTest is Test {
    ValueTypesDemo public demo;

    function setUp() public {
        demo = new ValueTypesDemo();
    }

    function testDefaultBool() public {
        assertEq(demo.defaultBool(), false);
    }

    function testDefaultUint() public {
        assertEq(demo.defaultUint(), 0);
    }

    function testStatusValue() public {
        assertEq(demo.getStatusValue(), 0); // Pending = 0
    }

    function testFlag() public {
        assertEq(demo.flag(), true);
    }
}
