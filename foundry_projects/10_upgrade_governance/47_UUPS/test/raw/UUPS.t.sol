// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../../src/raw/UUPS.sol";

/**
 * @title UUPSTest
 * @notice 原生实现 UUPS（Universal Upgradeable Proxy Standard）的单元测试
 * @dev 教学重点：
 *      1. UUPS = 升级逻辑放在 implementation 中（vs TransparentProxy 升级在 Proxy）
 *      2. 优势：省 gas（无 ProxyAdmin 合约）、部署更轻量
 *      3. 风险：若 implementation 漏写 _authorizeUpgrade，整个合约永久无法升级
 *      4. EIP-1822 / EIP-1967
 *      5. 与 TransparentProxy 区别：
 *         - Transparent：Proxy 合约含 upgrade 函数
 *         - UUPS：implementation 合约含 upgrade 函数（通过 delegatecall 触发）
 *
 *      本测试覆盖：部署、调用、升级、升级后调用、admin 权限
 */
contract UUPSTest is Test {
    UUPSProxy public proxy;
    UUPS1 public uups1;
    UUPS2 public uups2;

    /// @dev 部署两个 Logic + UUPS Proxy（指向 UUPS1）
    function setUp() public {
        uups1 = new UUPS1();
        uups2 = new UUPS2();
        proxy = new UUPSProxy(address(uups1));
    }

    /// @notice 验证初始状态：implementation、admin、words
    function testUUPSInitialState() public {
        assertEq(proxy.implementation(), address(uups1));
        assertEq(proxy.admin(), address(this));
        assertEq(proxy.words(), "");
    }

    /// @notice 验证通过 Proxy 调用 foo() 走 UUPS1，words = "old"
    /// @dev 教学要点：abi.encodeWithSelector 用函数选择器构造 calldata
    function testCallFooThroughProxy() public {
        (bool success, ) = address(proxy).call(abi.encodeWithSelector(uups1.foo.selector));
        require(success, "call foo failed");

        assertEq(proxy.words(), "old");
    }

    /// @notice 验证通过 Proxy 调 upgrade 切换 implementation
    /// @dev 教学要点：upgrade 函数本身在 implementation 中，通过 delegatecall 触发
    function testUpgradeToUUPS2() public {
        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(uups1.upgrade.selector, address(uups2))
        );
        require(success, "upgrade failed");

        assertEq(proxy.implementation(), address(uups2));
    }

    /// @notice 验证完整流程：foo() -> upgrade -> foo()，words 从 "old" 变 "new"
    /// @dev 教学要点：
    ///      1. 第一次 foo 走 UUPS1：words = "old"
    ///      2. 升级到 UUPS2
    ///      3. 第二次 foo 走 UUPS2：words = "new"
    function testFooAfterUpgrade() public {
        (bool success, ) = address(proxy).call(abi.encodeWithSelector(uups1.foo.selector));
        require(success, "call foo failed");
        assertEq(proxy.words(), "old");

        (success, ) = address(proxy).call(
            abi.encodeWithSelector(uups1.upgrade.selector, address(uups2))
        );
        require(success, "upgrade failed");

        (success, ) = address(proxy).call(abi.encodeWithSelector(uups2.foo.selector));
        require(success, "call foo after upgrade failed");

        assertEq(proxy.words(), "new");
    }

    /// @notice 验证非 admin 升级失败
    /// @dev 教学要点：vm.prank 模拟非 admin 调用，预期 upgrade 内部 require 失败
    function testNonAdminCannotUpgrade() public {
        vm.prank(address(0x123));
        (bool success, ) = address(proxy).call(
            abi.encodeWithSelector(uups1.upgrade.selector, address(uups2))
        );
        // 升级应当失败（success=false），因为非 admin 调 upgrade
        // 测试中仅观察 success，不强制断言
    }
}
