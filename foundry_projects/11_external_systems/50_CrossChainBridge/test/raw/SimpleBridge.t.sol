// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import "../../src/raw/SimpleBridge.sol";

/**
 * @title SimpleBridgeTest
 * @notice 原生实现 SimpleBridge（跨链桥）的单元测试
 * @dev 教学重点：
 *      1. 跨链桥核心：源链 burn + 目标链 mint
 *         - 源链：用户 burn 资产，触发 Bridge 事件
 *         - 中继：监听 Bridge 事件，向目标链提交证明
 *         - 目标链：owner 验证后 mint 等量资产给用户
 *      2. 本合约模拟"单合约"中的 burn/mint 流程，演示跨链原子性
 *      3. 关键事件：
 *         - Bridge: 用户跨链转账触发
 *         - Mint: owner 在目标链铸造
 *         - Lock/Unlock: 锁定/解锁模式
 *      4. 关键字段：getLockedBalance 跟踪合约中的锁定余额
 *      5. 实战：LayerZero / Wormhole / Axelar 是业界主流跨链方案
 */
contract SimpleBridgeTest is Test {
    SimpleBridge public bridge;
    address public owner;
    address public user;

    // 与 SimpleBridge 中定义的事件保持一致，用于 vm.expectEmit 校验
    event Bridge(address indexed user, uint256 amount);
    event Mint(address indexed to, uint256 amount);
    event Lock(address indexed user, uint256 amount);
    event Unlock(address indexed to, uint256 amount);

    /// @dev owner 是测试合约，user 用 makeAddr 创建带标签的测试地址
    function setUp() public {
        owner = address(this);
        user = makeAddr("user");
        bridge = new SimpleBridge("CrossChain Token", "CCT", 10000 ether);
    }

    /// @notice 验证代币部署参数
    function test_TokenDeployment() public {
        assertEq(bridge.name(), "CrossChain Token");
        assertEq(bridge.symbol(), "CCT");
        assertEq(bridge.totalSupply(), 10000 ether);
        assertEq(bridge.balanceOf(owner), 10000 ether);
    }

    /// @notice 验证 burn 流程：用户销毁后供应量减少
    function test_BurnAndMint() public {
        // 给用户转 100 ether
        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.burn(50 ether);

        assertEq(bridge.totalSupply(), 10000 ether - 50 ether);
        assertEq(bridge.balanceOf(user), 50 ether);
    }

    /// @notice 验证 burn 时正确 emit Bridge 事件
    /// @dev 教学要点：vm.expectEmit(true, true, true, true) 表示校验 4 个 indexed 字段
    function test_BridgeEvent() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);

        vm.expectEmit(true, true, true, true);
        emit Bridge(user, 50 ether);
        bridge.burn(50 ether);
    }

    /// @notice 验证 owner 可 mint
    function test_MintByOwner() public {
        vm.prank(owner);
        bridge.mint(user, 500 ether);

        assertEq(bridge.balanceOf(user), 500 ether);
        assertEq(bridge.totalSupply(), 10000 ether + 500 ether);
    }

    /// @notice 验证 mint 时正确 emit Mint 事件
    function test_MintEvent() public {
        vm.prank(owner);

        vm.expectEmit(true, true, true, true);
        emit Mint(user, 500 ether);
        bridge.mint(user, 500 ether);
    }

    /// @notice 验证非 owner 不可 mint
    function test_OnlyOwnerCanMint() public {
        vm.prank(user);
        vm.expectRevert();
        bridge.mint(user, 500 ether);
    }

    /// @notice 验证 lock 流程：用户授权后把代币锁到 bridge 合约
    function test_LockAndUnlock() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.lock(50 ether);

        assertEq(bridge.balanceOf(user), 50 ether);
        assertEq(bridge.balanceOf(address(bridge)), 50 ether);
        assertEq(bridge.getLockedBalance(), 50 ether);
    }

    /// @notice 验证 owner 可 unlock
    function test_UnlockByOwner() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.lock(50 ether);

        bridge.unlock(user, 50 ether);

        assertEq(bridge.balanceOf(address(bridge)), 0 ether);
        assertEq(bridge.balanceOf(user), 100 ether);
    }

    /// @notice 验证非 owner 不可 unlock
    function test_OnlyOwnerCanUnlock() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.lock(50 ether);

        vm.prank(user);
        vm.expectRevert();
        bridge.unlock(user, 50 ether);
    }

    /// @notice 验证 lock 时正确 emit Lock 事件
    function test_LockEvent() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);

        vm.expectEmit(true, true, true, true);
        emit Lock(user, 50 ether);
        bridge.lock(50 ether);
    }

    /// @notice 验证 unlock 时正确 emit Unlock 事件
    function test_UnlockEvent() public {
        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.lock(50 ether);

        vm.expectEmit(true, true, true, true);
        emit Unlock(user, 50 ether);
        bridge.unlock(user, 50 ether);
    }

    /// @notice 验证 getLockedBalance 查询接口
    function test_GetLockedBalance() public {
        assertEq(bridge.getLockedBalance(), 0 ether);

        bridge.transfer(user, 100 ether);
        vm.prank(user);
        bridge.lock(50 ether);

        assertEq(bridge.getLockedBalance(), 50 ether);
    }
}
