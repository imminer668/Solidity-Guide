// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {TransparentProxy} from "../../src/raw/TransparentProxy.sol";
import {Logic1} from "../../src/raw/Logic1.sol";
import {Logic2} from "../../src/raw/Logic2.sol";

/**
 * @title TransparentProxyTest
 * @notice 原生实现 TransparentProxy（透明代理）的单元测试
 * @dev 教学重点：
 *      1. 透明代理 vs 普通代理：
 *         - 普通代理：admin 调 Logic 函数会被 delegatecall
 *         - 透明代理：admin 调 Logic 函数被 reject（防止 admin 误操作 Logic）
 *      2. 核心规则：仅当 msg.sender != admin 时才转发到 implementation
 *      3. 教学要点：admin 路径只允许 admin 相关的 selector（upgrade/transferAdmin）
 *         这样可以避免 admin 调 Logic 函数时产生的"函数选择器冲突"
 *      4. 实战：OZ 的 TransparentUpgradeableProxy 是此模式的工业实现
 */
contract TransparentProxyTest is Test {
    TransparentProxy public proxy;
    Logic1 public logic1;
    Logic2 public logic2;

    /// @dev 部署两个 Logic + TransparentProxy（指向 Logic1）
    function setUp() public {
        logic1 = new Logic1();
        logic2 = new Logic2();
        proxy = new TransparentProxy(address(logic1));
    }

    /// @notice 验证初始 implementation 和 admin
    function testInitialState() public view {
        assertEq(proxy.implementation(), address(logic1));
        assertEq(proxy.admin(), address(this));
    }

    /// @notice 验证非 admin 调用 foo() 走 Logic1，words = "old"
    function testProxyCallThroughLogic1() public {
        vm.prank(address(0x1234));
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "old");
    }

    /// @notice 验证 admin 不能直接调 Logic 函数（透明代理特性）
    /// @dev 教学要点：admin 调 foo() 应当被拒绝，防止误用
    function testAdminCannotCallLogicContract() public {
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        assertEq(success, false);
    }

    /// @notice 验证非 admin 调用 Logic 函数成功
    function testNonAdminCanCallLogicContract() public {
        vm.prank(address(0x1234));
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call from non-admin should succeed");
        assertEq(proxy.words(), "old");
    }

    /// @notice 验证升级到 Logic2
    function testUpgrade() public {
        proxy.upgrade(address(logic2));
        assertEq(proxy.implementation(), address(logic2));
    }

    /// @notice 验证升级后非 admin 调用 foo() 走 Logic2，words = "new"
    function testProxyCallAfterUpgrade() public {
        proxy.upgrade(address(logic2));
        vm.prank(address(0x1234));
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "new");
    }

    /// @notice 验证非 admin 升级必须 revert
    function testOnlyAdminCanUpgrade() public {
        vm.prank(address(0x1234));
        vm.expectRevert();
        proxy.upgrade(address(logic2));
    }

    /// @notice 验证升级不影响 words
    function testWordsChangedByLogic1() public {
        vm.prank(address(0x1234));
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "old");

        proxy.upgrade(address(logic2));
        assertEq(proxy.words(), "old");

        vm.prank(address(0x1234));
        (bool success2, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success2, "Call failed");
        assertEq(proxy.words(), "new");
    }
}
