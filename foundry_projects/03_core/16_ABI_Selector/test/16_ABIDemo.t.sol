// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/16_ABIDemo.sol";

contract ABIDemoTest is Test {
    ABIDemo public demo;

    function setUp() public {
        demo = new ABIDemo();
    }

    function testEncodeAndDecode() public {
        bytes memory encoded = demo.encodeValues();
        (uint256 num, address addr) = demo.decodeValues(encoded);
        assertEq(num, 1);
        assertEq(addr, address(0x123));
    }

    function testSelector() public {
        bytes4 sel1 = demo.getSelector();
        assertEq(sel1, bytes4(keccak256("mint(address,uint256)")));
    }

    function testEncodeWithSig() public {
        bytes memory data = demo.encodeWithSig();
        // Selector + 参数编码
        assertTrue(data.length > 4);
    }
}
