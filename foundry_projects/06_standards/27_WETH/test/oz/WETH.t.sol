// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {WETH} from "../../src/oz/WETH.sol";

/**
 * @title WETHOzTest
 * @notice 基于 OpenZeppelin 模式实现的 WETH 单元测试
 * @dev 与 raw 对比：OZ 版继承 OZ 的 ERC20，存款逻辑包装在 deposit/withdraw 中。
 *      整体行为应与 WETH9 完全一致：
 *      - 1:1 锚定 ETH
 *      - 支持 receive/fallback 直接存款
 *      - 配套 withdraw 反向操作
 */
contract WETHOzTest is Test {
    WETH public weth;

    function setUp() public {
        weth = new WETH();
    }

    /// @notice 验证 deposit 行为
    function testDeposit() public {
        weth.deposit{value: 1 ether}();
        assertEq(weth.balanceOf(address(this)), 1 ether);
    }

    /// @notice 验证 totalSupply 同步增长
    function testTotalSupply() public {
        weth.deposit{value: 1 ether}();
        assertEq(weth.totalSupply(), 1 ether);
    }

    /// @notice 验证 fallback 存款路径
    function testFallbackDeposit() public {
        address(weth).call{value: 0.5 ether}("");
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
    }

    /// @notice 验证 WETH 的 ERC20 转账
    function testTransfer() public {
        weth.deposit{value: 1 ether}();
        weth.transfer(address(2), 0.5 ether);
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
        assertEq(weth.balanceOf(address(2)), 0.5 ether);
    }
}
