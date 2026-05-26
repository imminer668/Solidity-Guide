// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Minter} from "../../src/oz/ERC20Minter.sol";
import {TokenLockerOZ} from "../../src/oz/TokenLocker.sol";

/**
 * @title TokenLockerOZTest
 * @notice 基于 OZ 模式实现的 TokenLocker 单元测试
 * @dev 与 raw 对比：
 *      - 资金通过 ERC20Minter 注入（无需单独 mint+transfer）
 *      - OZ 实现通常不暴露 startTime 字段（封装在内部）
 *      - 业务行为与 raw 完全等价
 */
contract TokenLockerOZTest is Test {
    ERC20Minter public token;
    TokenLockerOZ public locker;
    address public beneficiary = address(1);

    /// @dev 部署时注入代币，OZ 版通过 mint 直接给 locker
    function setUp() public {
        token = new ERC20Minter("Test Token", "TEST");
        locker = new TokenLockerOZ(token, beneficiary, 100);
        token.mint(address(locker), 10000);
    }

    /// @notice 验证初始状态：受益人、锁仓时长
    /// @dev OZ 版不暴露 startTime getter，故省略该字段校验
    function testInitialState() public {
        assertEq(locker.beneficiary(), beneficiary);
        assertEq(locker.lockTime(), 100);
    }

    /// @notice 验证锁仓期内 release 必须 revert
    function testCannotReleaseBeforeLockTime() public {
        vm.expectRevert("TokenLock: current time is before release time");
        locker.release();
    }

    /// @notice 验证到期一次性释放
    function testReleaseAfterLockTime() public {
        vm.warp(block.timestamp + 101);
        locker.release();
        assertEq(token.balanceOf(beneficiary), 10000);
    }
}
