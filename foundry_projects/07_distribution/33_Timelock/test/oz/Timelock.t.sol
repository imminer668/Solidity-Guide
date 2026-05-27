// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {TimelockOZ} from "../../src/oz/Timelock.sol";

/**
 * @title TimelockOZTest
 * @notice 基于 OZ 模式实现的 Timelock 单元测试
 * @dev 与 raw 对比：
 *      - 接口保持一致：queueTransaction / executeTransaction / cancelTransaction
 *      - OZ 实现通常使用 access control（角色）而非单一 admin
 *      - 业务行为等价：延迟执行 + 队列管理
 */
contract TimelockOZTest is Test {
    TimelockOZ public timelock;
    address public admin;

    function setUp() public {
        timelock = new TimelockOZ(100);
        admin = address(this);
    }

    /// @notice 验证初始状态
    function testInitialState() public {
        assertEq(timelock.admin(), admin);
        assertEq(timelock.delay(), 100);
    }

    /// @notice 验证 queueTransaction 行为
    function testQueueTransaction() public {
        uint256 executeTime = block.timestamp + 200;
        bytes32 txHash = timelock.queueTransaction(
            address(1),
            0,
            "test()",
            "",
            executeTime
        );
        assertTrue(timelock.queuedTransactions(txHash));
    }

    /// @notice 验证到期后成功执行
    function testExecuteAfterDelay() public {
        uint256 executeTime = block.timestamp + 100;
        bytes32 txHash = timelock.queueTransaction(
            address(1),
            0,
            "test()",
            "",
            executeTime
        );
        vm.warp(executeTime + 1);
        timelock.executeTransaction(address(1), 0, "test()", "", executeTime);
        assertTrue(!timelock.queuedTransactions(txHash));
    }
}
