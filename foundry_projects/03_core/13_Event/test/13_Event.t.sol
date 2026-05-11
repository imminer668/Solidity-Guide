// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/13_Event.sol";

contract EventDemoTest is Test {
    EventDemo public token;

    // 在测试合约中声明事件，以便在 vm.expectEmit 中使用
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Mint(address indexed to, uint256 value);
    event Burn(address indexed from, uint256 value);

    function setUp() public {
        token = new EventDemo();
    }

    function testMintEmitsEvents() public {
        // vm.expectEmit 声明：接下来 token.emit 的事件应该和下面这行匹配
        vm.expectEmit(address(token));
        emit Mint(address(this), 1000);
        token.mint(address(this), 1000);

        // 验证余额
        assertEq(token.balanceOf(address(this)), 1000);
        assertEq(token.totalSupply(), 1000);
    }

    function testTransferEmitsEvent() public {
        token.mint(address(this), 1000);
        address to = address(0x1);

        // 声明期望由 token 发出的 Transfer 事件
        vm.expectEmit(address(token));
        emit Transfer(address(this), to, 300);
        token.transfer(to, 300);

        assertEq(token.balanceOf(address(this)), 700);
        assertEq(token.balanceOf(to), 300);
    }

    function testBurnEmitsEvent() public {
        token.mint(address(this), 1000);
        token.burn(500);

        assertEq(token.balanceOf(address(this)), 500);
        assertEq(token.totalSupply(), 500);
    }
}
