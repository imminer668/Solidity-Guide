// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SimpleUpgrade} from "../../src/raw/SimpleUpgrade.sol";
import {Logic1} from "../../src/raw/Logic1.sol";
import {Logic2} from "../../src/raw/Logic2.sol";

/**
 * @title SimpleUpgradeTest
 * @notice 原生实现 SimpleUpgrade（可升级代理）的单元测试
 * @dev 教学重点：
 *      1. 升级模式：Proxy 存储 + Logic1/Logic2 逻辑，admin 可切换 implementation
 *      2. 关键概念：
 *         - Proxy 持有 state（words 变量）
 *         - Logic1.foo() 把 words 设为 "old"
 *         - Logic2.foo() 把 words 设为 "new"
 *         - upgrade 切换 implementation，words 状态保留
 *      3. 教学要点：升级只是切换"代码指针"，存储数据不动
 *      4. admin 模式：仅 admin 可升级（教学用简单权限）
 *      5. 实战：应使用 OZ 的 TransparentUpgradeableProxy / UUPS
 */
contract SimpleUpgradeTest is Test {
    SimpleUpgrade public proxy;
    Logic1 public logic1;
    Logic2 public logic2;

    /// @dev 部署两个 Logic，proxy 初始指向 Logic1
    function setUp() public {
        logic1 = new Logic1();
        logic2 = new Logic2();
        proxy = new SimpleUpgrade(address(logic1));
    }

    /// @notice 验证初始 implementation 和 admin
    function testInitialState() public view {
        assertEq(proxy.implementation(), address(logic1));
        assertEq(proxy.admin(), address(this));
    }

    /// @notice 验证通过 Logic1 调用 foo() 后 words = "old"
    /// @dev 教学要点：直接用 address(proxy).call(...)，让 proxy 的 fallback 转发
    function testProxyCallThroughLogic1() public {
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "old");
    }

    /// @notice 验证升级到 Logic2 后 implementation 切换
    function testUpgrade() public {
        proxy.upgrade(address(logic2));
        assertEq(proxy.implementation(), address(logic2));
    }

    /// @notice 验证升级后调用 foo() 走 Logic2 逻辑
    function testProxyCallAfterUpgrade() public {
        proxy.upgrade(address(logic2));
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "new");
    }

    /// @notice 验证非 admin 升级必须 revert
    /// @dev 教学要点：vm.expectRevert() 不带参数表示仅校验是否 revert
    function testOnlyAdminCanUpgrade() public {
        vm.prank(address(0x1234));
        vm.expectRevert();
        proxy.upgrade(address(logic2));
    }

    /// @notice 验证升级不影响已写入的 words
    /// @dev 教学要点：升级只改代码指针，storage 不动
    function testWordsChangedByLogic1() public {
        (bool success, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success, "Call failed");
        assertEq(proxy.words(), "old");

        proxy.upgrade(address(logic2));
        assertEq(proxy.words(), "old"); // words 升级后保持 "old"

        (bool success2, ) = address(proxy).call(abi.encodeWithSignature("foo()"));
        require(success2, "Call failed");
        assertEq(proxy.words(), "new");
    }
}
