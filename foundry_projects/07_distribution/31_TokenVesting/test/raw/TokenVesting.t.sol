// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../../src/raw/ERC20.sol";
import {TokenVesting} from "../../src/raw/TokenVesting.sol";

/**
 * @title TokenVestingRawTest
 * @notice 原生实现 TokenVesting（线性解锁）的单元测试
 * @dev 教学重点：
 *      1. TokenVesting 是项目方/团队代币按时间线性释放的常见模式
 *      2. 关键参数：beneficiary（受益人）、start（开始时间）、duration（解锁周期）
 *      3. vestedAmount = total * (now - start) / duration（线性插值）
 *      4. release() 将已 vested 的部分转账给 beneficiary
 *
 *      Foundry 技巧：vm.warp(timestamp) 推进 block.timestamp
 */
contract TokenVestingRawTest is Test {
    ERC20 public token;
    TokenVesting public vesting;
    address public beneficiary = address(1);

    /// @dev 部署 vesting 时锁定 beneficiary=address(1), duration=100
    ///      之后向 vesting 转入 10000 token 作为待释放池
    function setUp() public {
        token = new ERC20();
        vesting = new TokenVesting(beneficiary, 100);
        token.mint(address(vesting), 10000);
    }

    /// @notice 验证初始状态：受益人、开始时间、周期
    /// @dev 教学要点：block.timestamp 在 setUp 时取一次，后续测试用 vm.warp 控制
    function testInitialState() public {
        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(vesting.start(), block.timestamp);
        assertEq(vesting.duration(), 100);
    }

    /// @notice 验证起始时已 vested 数量为 0
    function testVestedAmountAtStart() public {
        assertEq(vesting.vestedAmount(address(token), block.timestamp), 0);
    }

    /// @notice 验证满 duration 后，100% 解锁
    function testVestedAmountAfterDuration() public {
        vm.warp(block.timestamp + 100);
        assertEq(vesting.vestedAmount(address(token), block.timestamp), 10000);
    }

    /// @notice 验证中点（50% duration）可领 50%
    function testRelease() public {
        vm.warp(block.timestamp + 50);
        vesting.release(address(token));
        assertEq(token.balanceOf(beneficiary), 5000);
    }
}
