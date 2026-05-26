// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../../src/raw/ERC20.sol";
import {TokenLocker} from "../../src/raw/TokenLocker.sol";

/**
 * @title TokenLockerRawTest
 * @notice 原生实现 TokenLocker（代币锁仓）的单元测试
 * @dev 教学重点：
 *      1. TokenLocker 是"到期一次性释放"模式，与 TokenVesting 的"线性释放"不同
 *      2. 锁定期内 release() 必须 revert
 *      3. 关键字段：beneficiary、lockTime（锁仓秒数）、startTime（部署时的时间戳）
 *      4. 实战场景：DEX 上线前的项目方代币流动性锁定
 */
contract TokenLockerRawTest is Test {
    ERC20 public token;
    TokenLocker public locker;
    address public beneficiary = address(1);

    /// @dev 部署时锁定 beneficiary、lockTime=100s，并向 locker 注入 10000 token
    function setUp() public {
        token = new ERC20();
        locker = new TokenLocker(token, beneficiary, 100);
        token.mint(address(locker), 10000);
    }

    /// @notice 验证初始状态：受益人、锁仓时长、开始时间
    function testInitialState() public {
        assertEq(locker.beneficiary(), beneficiary);
        assertEq(locker.lockTime(), 100);
        assertEq(locker.startTime(), block.timestamp);
    }

    /// @notice 验证锁仓期内 release 必须 revert
    /// @dev 教学要点：vm.expectRevert 必须在调用前设置，匹配 revert 字符串
    function testCannotReleaseBeforeLockTime() public {
        vm.expectRevert("TokenLock: current time is before release time");
        locker.release();
    }

    /// @notice 验证超过 lockTime 后一次性释放全部代币
    /// @dev vm.warp +101 秒，跳过 100 秒锁仓期
    function testReleaseAfterLockTime() public {
        vm.warp(block.timestamp + 101);
        locker.release();
        assertEq(token.balanceOf(beneficiary), 10000);
    }
}
