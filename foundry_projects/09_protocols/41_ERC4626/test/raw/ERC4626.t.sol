// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC4626} from "../../src/raw/ERC4626.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

/**
 * @title ERC4626RawTest
 * @notice 原生实现 ERC4626（代币化金库）的单元测试
 * @dev 教学重点：
 *      1. ERC4626 是"代币化金库"标准：用户存入底层资产（asset），获得份额（share）
 *      2. 关键概念：
 *         - asset: 底层资产（如 USDC）
 *         - share: 金库发给存款人的凭证
 *         - 1:1 起步：首次 deposit 时 share == asset
 *         - 后续按比例：share = asset * totalSupply / totalAssets
 *      3. 操作：
 *         - deposit/mint: 资产 -> 份额
 *         - withdraw/redeem: 份额 -> 资产
 *         - convertToShares/convertToAssets: 静态换算
 *      4. 实战场景：Aave、Compound、Lido 都基于 ERC4626
 *
 *      测试中用 OZ 的 ERC20Mock 作为底层资产，仅依赖标准 mint/approve 接口
 */
contract ERC4626RawTest is Test {
    ERC4626 public vault;
    ERC20Mock public asset;

    /// @dev 部署金库，给测试合约铸造 10000e18 资产并授权
    function setUp() public {
        asset = new ERC20Mock();
        vault = new ERC4626(asset, "vFOne", "v");

        asset.mint(address(this), 10000e18);
        asset.approve(address(vault), type(uint256).max);
    }

    /// @notice 验证底层资产地址绑定正确
    function testAsset() public view {
        assertEq(vault.asset(), address(asset));
    }

    /// @notice 验证初始 totalAssets 为 0
    function testTotalAssets() public view {
        assertEq(vault.totalAssets(), 0);
    }

    /// @notice 验证 deposit：首存 1:1
    function testDeposit() public {
        uint256 assets = 1000e18;
        uint256 shares = vault.deposit(assets, address(this));

        assertEq(shares, assets);
        assertEq(vault.balanceOf(address(this)), assets);
        assertEq(vault.totalAssets(), assets);
        assertEq(asset.balanceOf(address(this)), 10000e18 - assets);
    }

    /// @notice 验证 mint：指定 share 数量，反算所需资产
    function testMint() public {
        uint256 shares = 1000e18;
        uint256 assets = vault.mint(shares, address(this));

        assertEq(shares, assets);
        assertEq(vault.balanceOf(address(this)), shares);
        assertEq(vault.totalAssets(), shares);
    }

    /// @notice 验证 withdraw：销毁份额，提取资产
    function testWithdraw() public {
        vault.deposit(1000e18, address(this));
        assertEq(vault.balanceOf(address(this)), 1000e18);

        uint256 assets = 500e18;
        uint256 shares = vault.withdraw(assets, address(this), address(this));

        assertEq(shares, assets);
        assertEq(vault.balanceOf(address(this)), 500e18);
        assertEq(vault.totalAssets(), 500e18);
    }

    /// @notice 验证 redeem：销毁份额，提取资产
    function testRedeem() public {
        vault.deposit(1000e18, address(this));
        assertEq(vault.balanceOf(address(this)), 1000e18);

        uint256 shares = 500e18;
        uint256 assets = vault.redeem(shares, address(this), address(this));

        assertEq(assets, shares);
        assertEq(vault.balanceOf(address(this)), 500e18);
        assertEq(vault.totalAssets(), 500e18);
    }

    /// @notice 验证 convertToShares 换算函数
    function testConvertToShares() public view {
        assertEq(vault.convertToShares(1000e18), 1000e18);
    }

    /// @notice 验证 convertToAssets 换算函数
    function testConvertToAssets() public view {
        assertEq(vault.convertToAssets(1000e18), 1000e18);
    }

    /// @notice 验证 maxDeposit：未限制时为 uint256.max
    function testMaxDeposit() public view {
        assertEq(vault.maxDeposit(address(this)), type(uint256).max);
    }

    /// @notice 验证 maxWithdraw：无存款时为 0
    function testMaxWithdraw() public view {
        assertEq(vault.maxWithdraw(address(this)), 0);
    }

    /// @notice 验证 maxRedeem：无份额时为 0
    function testMaxRedeem() public view {
        assertEq(vault.maxRedeem(address(this)), 0);
    }

    /// @notice 验证多 LP 按比例存款：第二个 LP 拿到的份额与首存一致
    /// @dev 教学要点：当 totalAssets == totalSupply 时，share == assets
    function testProportionalDeposit() public {
        // 第一个存款人
        vault.deposit(1000e18, address(this));
        assertEq(vault.balanceOf(address(this)), 1000e18);
        assertEq(vault.totalAssets(), 1000e18);

        // 第二个存款人
        asset.mint(address(0xAbcd), 1000e18);
        vm.prank(address(0xAbcd));
        asset.approve(address(vault), type(uint256).max);
        vm.prank(address(0xAbcd));
        uint256 shares = vault.deposit(1000e18, address(0xAbcd));

        assertEq(shares, 1000e18);
        assertEq(vault.balanceOf(address(0xAbcd)), 1000e18);
    }
}
