// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20PermitOZ} from "../../src/oz/ERC20Permit.sol";

/**
 * @title ERC20PermitOZTest
 * @notice 基于 OZ 模式实现的 ERC20Permit 单元测试
 * @dev 与 raw 对比：
 *      - 继承 OZ 的 ERC20 + ERC20Permit，签名/重放/过期逻辑均使用 OZ 实现
 *      - DOMAIN_SEPARATOR、typeHash 内部一致
 *      - 业务流程：链下签名 -> spender 调用 permit -> allowance 生效
 */
contract ERC20PermitOZTest is Test {
    ERC20PermitOZ public token;
    uint256 public ownerPrivateKey = 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b;
    address public ownerAddr;
    address public spender;

    function setUp() public {
        ownerAddr = vm.addr(ownerPrivateKey);
        spender = address(0x1234);
        token = new ERC20PermitOZ("TestToken", "TT");
    }

    /// @notice 验证初始元数据
    function testInitialState() public view {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TT");
        assertEq(token.decimals(), 18);
    }

    /// @notice 验证 mint 行为
    function testMint() public {
        token.mint(ownerAddr, 1000e18);
        assertEq(token.balanceOf(ownerAddr), 1000e18);
    }

    /// @notice 验证 permit 完整流程
    /// @dev 与 raw 流程相同：构造 digest -> 签名 -> spender 调用 permit
    function testPermit() public {
        token.mint(ownerAddr, 1000e18);

        uint256 value = 500e18;
        uint256 deadline = type(uint256).max;
        uint256 nonce = token.nonces(ownerAddr);

        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();
        bytes32 structHash = keccak256(abi.encode(
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
            ownerAddr,
            spender,
            value,
            nonce,
            deadline
        ));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);

        vm.prank(spender);
        token.permit(ownerAddr, spender, value, deadline, v, r, s);

        assertEq(token.allowance(ownerAddr, spender), value);
    }
}
