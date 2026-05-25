// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Minter} from "../../src/oz/ERC20Minter.sol";
import {TokenVestingOZ} from "../../src/oz/TokenVesting.sol";

/**
 * @title TokenVestingOZTest
 * @notice 基于 OZ 模式实现的 TokenVesting 单元测试
 * @dev 与 raw 对比：
 *      - 资金通过 ERC20Minter 铸造给 vesting 合约
 *      - 解锁逻辑与 raw 完全等价：线性插值
 *      - OZ 实现常附 ERC20Released 事件，便于链上追踪
 */
contract TokenVestingOZTest is Test {
    ERC20Minter public token;
    TokenVestingOZ public vesting;
    address public beneficiary = address(1);

    /// @dev 部署时显式传入 name/symbol，再 mint 给 vesting
    function setUp() public {
        token = new ERC20Minter("Test Token", "TEST");
        vesting = new TokenVestingOZ(beneficiary, 100);
        token.mint(address(vesting), 10000);
    }

    /// @notice 验证初始状态：受益人、周期
    /// @dev OZ 版不一定暴露 start() 字段，故只校验 beneficiary + duration
    function testInitialState() public {
        assertEq(vesting.beneficiary(), beneficiary);
        assertEq(vesting.duration(), 100);
    }

    /// @notice 验证满 duration 后 100% 解锁
    function testVestedAmountAfterDuration() public {
        vm.warp(block.timestamp + 100);
        assertEq(vesting.vestedAmount(address(token), block.timestamp), 10000);
    }

    /// @notice 验证中点 50% 可领
    function testRelease() public {
        vm.warp(block.timestamp + 50);
        vesting.release(address(token));
        assertEq(token.balanceOf(beneficiary), 5000);
    }
}
