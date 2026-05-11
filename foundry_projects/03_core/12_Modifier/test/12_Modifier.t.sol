// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/12_Modifier.sol";

contract SecureContractTest is Test {
    SecureContract public contract_;
    address public owner = address(this);
    address public admin = address(0x1);
    address public stranger = address(0x2);

    function setUp() public {
        contract_ = new SecureContract();
        // 添加 admin
        contract_.addAdmin(admin);
    }

    // 测试：owner 可以设置值
    function testOwnerCanSetValue() public {
        contract_.setValue(100);
        assertEq(contract_.storedValue(), 100);
    }

    // 测试：admin 可以设置值
    function testAdminCanSetValue() public {
        vm.prank(admin); // 模拟 admin 调用
        contract_.setValue(200);
        assertEq(contract_.storedValue(), 200);
    }

    // 测试：stranger 不能设置值
    function testStrangerCannotSetValue() public {
        vm.prank(stranger); // 模拟 stranger 调用
        vm.expectRevert(NotAdmin.selector);
        contract_.setValue(300);
    }

    // 测试：owner 可以添加 admin
    function testOwnerCanAddAdmin() public {
        contract_.addAdmin(stranger);
        assertEq(contract_.admins(stranger), true);
    }

    // 测试：pause 后 admin 无法 setValue
    function testPausedBlocksAdmin() public {
        contract_.pause();
        vm.prank(admin);
        vm.expectRevert("Paused");
        contract_.setValue(400);
    }
}
