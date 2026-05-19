// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../../src/raw/ERC20.sol";

/**
 * @title ERC20RawTest
 * @notice 原生实现 ERC20 的单元测试
 * @dev 教学重点：
 *      1. Foundry 测试约定：以 `contract <Name>Test is Test` 形式组织
 *      2. setUp() 在每个测试函数前执行，用于初始化状态
 *      3. address(this) 在测试中代表 test contract 自身，常作为默认 msg.sender
 *      4. assertEq 会在左右不相等时输出差异，方便排错
 */
contract ERC20RawTest is Test {
    ERC20 public token;

    /// @dev 每个测试前都会重新部署，确保测试之间互不污染状态
    function setUp() public {
        token = new ERC20("Test Token", "TTK");
    }

    /// @notice 测试初始总供应量应为 0
    /// @dev 体现 ERC20 的"显式铸造"理念：部署时不自动给任何人铸币
    function testInitialSupply() public {
        assertEq(token.totalSupply(), 0);
    }

    /// @notice 验证 mint 后总供应量与接收方余额同时增加
    /// @dev 教学要点：mint 必须同时影响 totalSupply 与接收方 balanceOf，二者保持同步
    function testMint() public {
        token.mint(1000);
        assertEq(token.totalSupply(), 1000);
        assertEq(token.balanceOf(address(this)), 1000);
    }

    /// @notice 验证 transfer 在余额充足时正确更新双方余额
    function testTransfer() public {
        token.mint(1000);
        token.transfer(address(1), 500);
        assertEq(token.balanceOf(address(this)), 500);
        assertEq(token.balanceOf(address(1)), 500);
    }

    /// @notice 验证 transfer 在余额不足时必须 revert
    /// @dev 教学要点：vm.expectRevert() 表示"下一调用必须失败"
    ///      不带参数表示只检查是否 revert，不校验具体原因
    function testTransferFail() public {
        token.mint(1000);
        vm.expectRevert();
        token.transfer(address(1), 1001);
    }

    /// @notice 验证 approve + transferFrom 组合：授权-转账两步流程
    /// @dev 教学要点：ERC20 的 transferFrom 是"代扣"机制，
    ///      spender 必须先被 owner 授权额度，才能代为转账
    function testApproveAndTransferFrom() public {
        token.mint(1000);
        token.approve(address(this), 500);

        token.transferFrom(address(this), address(1), 300);

        assertEq(token.balanceOf(address(1)), 300);
        assertEq(token.balanceOf(address(this)), 700);
    }

    /// @notice 验证 burn 销毁后总供应量同步减少
    function testBurn() public {
        token.mint(1000);
        token.burn(500);
        assertEq(token.totalSupply(), 500);
        assertEq(token.balanceOf(address(this)), 500);
    }
}
