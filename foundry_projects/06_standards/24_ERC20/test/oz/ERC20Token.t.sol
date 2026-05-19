// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Token} from "../../src/oz/ERC20Token.sol";

/**
 * @title ERC20TokenTest
 * @notice 基于 OpenZeppelin ERC20 实现的单元测试
 * @dev 与 raw 版本对比：OZ 实现继承 OZ 的 ERC20，
 *      行为完全符合 EIP-20 标准，并附带了事件、name/symbol/decimals 等完整接口
 *
 *      教学重点：
 *      1. OZ 实现是行业标准，被审计过、经过生产验证
 *      2. 同样的测试逻辑可用于校验 OZ 实现与 EIP-20 标准的兼容性
 *      3. 两个版本测试结果应一致，差异体现在代码量、安全性和功能完整性
 */
contract ERC20TokenTest is Test {
    ERC20Token public token;

    /// @dev 部署时显式传入 decimals，便于对比 raw 版本（hardcode 18）
    function setUp() public {
        token = new ERC20Token("Test Token", "TTK", 18);
    }

    /// @notice 验证初始总供应量为 0
    /// @dev OZ 的 ERC20 默认不进行任何铸币，符合 EIP-20 规范
    function testInitialSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    /// @notice 验证 mint 行为与 raw 一致
    function testMint() public {
        token.mint(1000);
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
    }

    /// @notice 验证 transfer 在余额充足时正确生效
    function testTransfer() public {
        token.mint(1000);
        token.transfer(address(1), 500);
        assertEq(token.balanceOf(address(this)), 500);
        assertEq(token.balanceOf(address(1)), 500);
    }

    /// @notice 验证 transfer 在余额不足时必须 revert
    /// @dev OZ 的 ERC20 内部会校验余额，行为应与 raw 一致
    function testTransferFail() public {
        token.mint(1000);
        vm.expectRevert();
        token.transfer(address(1), 1001);
    }

    /// @notice 验证 approve + transferFrom 流程
    /// @dev OZ 的 ERC20 会发出 Approval/Transfer 事件，便于链上追踪
    function testApproveAndTransferFrom() public {
        token.mint(1000);
        token.approve(address(this), 500);

        token.transferFrom(address(this), address(1), 300);

        assertEq(token.balanceOf(address(1)), 300);
        assertEq(token.balanceOf(address(this)), 700);
    }

    /// @notice 验证 burn 后供应量与余额同步减少
    function testBurn() public {
        token.mint(1000);
        token.burn(500);
        assertEq(token.totalSupply(), 500);
        assertEq(token.balanceOf(address(this)), 500);
    }
}
