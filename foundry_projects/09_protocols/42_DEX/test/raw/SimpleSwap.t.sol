// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SimpleSwap, IERC20} from "../../src/raw/SimpleSwap.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title SimpleSwapRawTest
 * @notice 原生实现 SimpleSwap（Uniswap V2 风格 AMM）的单元测试
 * @dev 教学重点：
 *      1. AMM = 自动做市商：用 x*y=k 恒定乘积公式定价
 *      2. 关键公式：
 *         - getAmountOut = amountIn * reserveOut / (reserveIn + amountIn)
 *         - 无手续费版（教学演示），生产应扣 0.3% 手续费
 *      3. 流动性：
 *         - 首存：liquidity = sqrt(amount0 * amount1)
 *         - 后续：按 reserve 比例 share
 *         - 销毁 LP 时按比例取回
 *      4. 教学要点：先 addLiquidity 才能 swap
 *      5. Foundry cheatcode: vm.prank(addr) 模拟指定地址调用
 */
contract SimpleSwapRawTest is Test {
    SimpleSwap public swap;
    ERC20Mock public token0;
    ERC20Mock public token1;

    /// @dev 部署两个 ERC20 mock + 简单 swap 合约，铸造 10000e18 给测试合约
    function setUp() public {
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();
        swap = new SimpleSwap(IERC20(address(token0)), IERC20(address(token1)));

        token0.mint(address(this), 10000e18);
        token1.mint(address(this), 10000e18);

        token0.approve(address(swap), type(uint256).max);
        token1.approve(address(swap), type(uint256).max);
    }

    /// @notice 验证初始状态：token 绑定 + 储备为 0
    function testInitialState() public view {
        assertEq(address(swap.token0()), address(token0));
        assertEq(address(swap.token1()), address(token1));
        assertEq(swap.reserve0(), 0);
        assertEq(swap.reserve1(), 0);
        assertEq(swap.totalSupply(), 0);
    }

    /// @notice 验证首次添加流动性：LP = sqrt(amount0 * amount1)
    /// @dev 教学要点：amount0=amount1=100e18 时 LP = 100e18
    function testAddLiquidity() public {
        uint256 amount0 = 100e18;
        uint256 amount1 = 100e18;

        uint256 liquidity = swap.addLiquidity(amount0, amount1);

        assertEq(liquidity, 100e18);
        assertEq(swap.balanceOf(address(this)), 100e18);
        assertEq(swap.reserve0(), amount0);
        assertEq(swap.reserve1(), amount1);
    }

    /// @notice 验证多 LP 按比例添加流动性
    /// @dev 第二个 LP 同样存 100/100，应当也得到 100 LP
    function testAddLiquidityMultipleLPs() public {
        swap.addLiquidity(100e18, 100e18);

        token0.mint(address(0xAbcd), 1000e18);
        token1.mint(address(0xAbcd), 1000e18);
        vm.prank(address(0xAbcd));
        token0.approve(address(swap), type(uint256).max);
        vm.prank(address(0xAbcd));
        token1.approve(address(swap), type(uint256).max);

        vm.prank(address(0xAbcd));
        uint256 liquidity = swap.addLiquidity(100e18, 100e18);

        assertEq(liquidity, 100e18);
        assertEq(swap.balanceOf(address(0xAbcd)), 100e18);
    }

    /// @notice 验证 swap：10 token0 换 token1
    /// @dev 教学要点：amountOut = 10 * 100 / (100 + 10) ≈ 9.09e18
    function testSwap() public {
        swap.addLiquidity(100e18, 100e18);

        uint256 amountIn = 10e18;
        uint256 expectedOut = swap.getAmountOut(amountIn, 100e18, 100e18);

        (uint256 amountOut, IERC20 tokenOut) = swap.swap(amountIn, IERC20(address(token0)), 0);

        assertEq(address(tokenOut), address(token1));
        assertEq(amountOut, expectedOut);
        assertEq(amountOut, 9090909090909090909);
    }

    /// @notice 验证销毁 LP 取回两种 token
    function testRemoveLiquidity() public {
        uint256 liquidity = swap.addLiquidity(100e18, 100e18);
        assertEq(swap.balanceOf(address(this)), 100e18);

        (uint256 amount0, uint256 amount1) = swap.removeLiquidity(liquidity);

        assertEq(amount0, 100e18);
        assertEq(amount1, 100e18);
        assertEq(swap.balanceOf(address(this)), 0);
        assertEq(swap.totalSupply(), 0);
    }

    /// @notice 验证 getAmountOut 公式
    function testGetAmountOut() public view {
        uint256 amountIn = 10e18;
        uint256 reserveIn = 100e18;
        uint256 reserveOut = 100e18;

        uint256 amountOut = swap.getAmountOut(amountIn, reserveIn, reserveOut);

        assertEq(amountOut, 9090909090909090909);
    }
}
