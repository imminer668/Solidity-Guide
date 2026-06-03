// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SimpleSwapOZ} from "../../src/oz/SimpleSwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title SimpleSwapOZTest
 * @notice 基于 OZ 模式实现的 SimpleSwap 单元测试
 * @dev 与 raw 对比：
 *      - OZ 实现使用 OZ 的 IERC20 接口（更安全）
 *      - AMM 核心公式保持一致
 *      - 业务行为等价
 */
contract SimpleSwapOZTest is Test {
    SimpleSwapOZ public swap;
    ERC20Mock public token0;
    ERC20Mock public token1;

    function setUp() public {
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        swap = new SimpleSwapOZ(IERC20(address(token0)), IERC20(address(token1)));

        token0.mint(address(this), 10000e18);
        token1.mint(address(this), 10000e18);

        token0.approve(address(swap), type(uint256).max);
        token1.approve(address(swap), type(uint256).max);
    }

    /// @notice 验证 token 绑定
    function testInitialState() public view {
        assertEq(address(swap.token0()), address(token0));
        assertEq(address(swap.token1()), address(token1));
    }

    /// @notice 验证首存 LP = sqrt(amount0 * amount1)
    function testAddLiquidity() public {
        uint256 amount0 = 100e18;
        uint256 amount1 = 100e18;

        uint256 liquidity = swap.addLiquidity(amount0, amount1);
        assertEq(liquidity, 100e18);
    }
}
