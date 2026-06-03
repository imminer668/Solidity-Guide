// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC4626} from "../../src/oz/ERC4626.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title ERC4626OZTest
 * @notice 基于 OZ 模式实现的 ERC4626 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版继承 OZ 的 ERC4626，全部按 EIP-4626 规范实现
 *      - 接口与 raw 完全一致：deposit/mint/withdraw/redeem
 *      - 业务行为等价
 */
contract ERC4626OZTest is Test {
    ERC4626 public vault;
    ERC20Mock public asset;

    function setUp() public {
        asset = new ERC20Mock();
        vault = new ERC4626(asset, "vFOne", "vFOne");

        asset.mint(address(this), 10000e18);
        asset.approve(address(vault), type(uint256).max);
    }

    /// @notice 验证 asset() 绑定
    function testAsset() public view {
        assertEq(vault.asset(), address(asset));
    }

    /// @notice 验证初始 totalAssets
    function testTotalAssets() public view {
        assertEq(vault.totalAssets(), 0);
    }

    /// @notice 验证 deposit
    function testDeposit() public {
        uint256 assets = 1000e18;
        uint256 shares = vault.deposit(assets, address(this));

        assertEq(shares, assets);
        assertEq(vault.balanceOf(address(this)), assets);
    }

    /// @notice 验证 mint
    function testMint() public {
        uint256 shares = 1000e18;
        uint256 assets = vault.mint(shares, address(this));

        assertEq(shares, assets);
        assertEq(vault.balanceOf(address(this)), shares);
    }

    /// @notice 验证 withdraw
    function testWithdraw() public {
        vault.deposit(1000e18, address(this));
        vault.withdraw(500e18, address(this), address(this));

        assertEq(vault.balanceOf(address(this)), 500e18);
    }

    /// @notice 验证 redeem
    function testRedeem() public {
        vault.deposit(1000e18, address(this));
        vault.redeem(500e18, address(this), address(this));

        assertEq(vault.balanceOf(address(this)), 500e18);
    }
}
