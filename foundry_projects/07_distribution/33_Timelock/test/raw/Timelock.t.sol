// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {Timelock} from "../../src/raw/Timelock.sol";

/**
 * @title TimelockRawTest
 * @notice 原生实现 Timelock（时间锁）的单元测试
 * @dev 教学重点：
 *      1. Timelock 是"延迟执行"模式：管理员排队后必须等 delay 才能执行
 *      2. 三段式生命周期：queueTransaction -> 等待 -> executeTransaction
 *      3. cancelTransaction 用于撤销未执行的排队项
 *      4. getTxHash 是工具函数：参数哈希后作为 queuedTransactions 的 key
 *      5. 应用场景：Compound/OpenZeppelin Governor 都基于 Timelock 实现
 */
contract TimelockRawTest is Test {
    Timelock public timelock;
    address public admin;

    /// @dev 部署时设置 delay=100s，admin 默认是测试合约 address(this)
    function setUp() public {
        timelock = new Timelock(100);
        admin = address(this);
    }

    /// @notice 验证初始 admin 和 delay
    function testInitialState() public {
        assertEq(timelock.admin(), admin);
        assertEq(timelock.delay(), 100);
    }

    /// @notice 验证 queueTransaction 后交易被标记为 queued
    /// @dev 教学要点：txHash = keccak256(target, value, signature, data, eta)
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

    /// @notice 验证未到时间执行必须 revert
    /// @dev 教学要点：executeTransaction 内部会校验 block.timestamp >= eta
    function testCannotExecuteBeforeTime() public {
        uint256 executeTime = block.timestamp + 200;
        timelock.queueTransaction(
            address(1),
            0,
            "test()",
            "",
            executeTime
        );
        vm.expectRevert("Timelock::executeTransaction: Transaction hasn't surpassed time lock.");
        timelock.executeTransaction(address(1), 0, "test()", "", executeTime);
    }

    /// @notice 验证达到执行时间后，executeTransaction 成功并清除 queued 标记
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

    /// @notice 验证管理员可取消未执行的排队项
    function testCancelTransaction() public {
        uint256 executeTime = block.timestamp + 200;
        bytes32 txHash = timelock.queueTransaction(
            address(1),
            0,
            "test()",
            "",
            executeTime
        );
        timelock.cancelTransaction(address(1), 0, "test()", "", executeTime);
        assertTrue(!timelock.queuedTransactions(txHash));
    }

    /// @notice 验证 getTxHash 工具函数
    /// @dev 教学要点：view 函数可标注 public view 节省 gas（不会上链）
    function testGetTxHash() public view {
        bytes32 hash = timelock.getTxHash(address(1), 100, "transfer(address,uint256)", "", 1000);
        assertTrue(hash != bytes32(0));
    }
}
