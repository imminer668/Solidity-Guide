// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Permit} from "../../src/raw/ERC20Permit.sol";

/**
 * @title ERC20PermitRawTest
 * @notice 原生实现 ERC20Permit（EIP-2612 gasless approve）的单元测试
 * @dev 教学重点：
 *      1. EIP-2612 解决了传统 ERC20 的痛点：用户必须先发 approve 交易，再发 transferFrom
 *         两笔交易 = 两次 gas。Permit 让用户链下签名授权，spender 一次交易完成
 *      2. 关键字段：nonces（防重放）、DOMAIN_SEPARATOR（区分 dapp/链）、deadline
 *      3. permit() 内部会：
 *         - 用 ecrecover 还原签名地址
 *         - 校验签名地址 == owner
 *         - 校验 deadline 未过期
 *         - 校验 nonce 匹配
 *         - 设置 allowance 并自增 nonce
 *      4. 实战场景：Uniswap 添加流动性、AAVE 存款都支持 permit
 */
contract ERC20PermitRawTest is Test {
    ERC20Permit public token;
    uint256 public ownerPrivateKey = 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b;
    address public ownerAddr;
    address public spender;

    /// @dev ownerAddr = vm.addr(privateKey)，spender 用任意地址模拟
    function setUp() public {
        ownerAddr = vm.addr(ownerPrivateKey);
        spender = address(0x1234);
        token = new ERC20Permit("TestToken", "TT");
    }

    /// @notice 验证初始 name/symbol/decimals/totalSupply
    function testInitialState() public view {
        assertEq(token.name(), "TestToken");
        assertEq(token.symbol(), "TT");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), 0);
    }

    /// @notice 验证 mint 行为
    function testMint() public {
        token.mint(ownerAddr, 1000e18);
        assertEq(token.balanceOf(ownerAddr), 1000e18);
        assertEq(token.totalSupply(), 1000e18);
    }

    /// @notice 验证普通 transfer
    function testTransfer() public {
        token.mint(ownerAddr, 1000e18);
        vm.prank(ownerAddr);
        token.transfer(spender, 500e18);
        assertEq(token.balanceOf(spender), 500e18);
    }

    /// @notice 验证 permit 完整流程：链下签名 -> 链上设置 allowance
    /// @dev 教学要点：
    ///      1. typeHash 必须与合约内 _PERMIT_TYPEHASH 完全一致
    ///      2. nonce = token.nonces(ownerAddr) 必须匹配当前状态
    ///      3. digest 构造："\x19\x01" + DOMAIN_SEPARATOR + structHash
    ///      4. permit 后 allowance 被设置，nonce 自增 1
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

        // spender 调用 permit（无需 owner 支付 gas）
        vm.prank(spender);
        token.permit(ownerAddr, spender, value, deadline, v, r, s);

        assertEq(token.allowance(ownerAddr, spender), value);
        assertEq(token.nonces(ownerAddr), nonce + 1);
    }

    /// @notice 验证伪造签名必须 revert
    /// @dev vm.sign(pk, bytes32(0)) 生成的签名用于"虚假"测试，必然无效
    function testPermitWithInvalidSignature() public {
        uint256 value = 500e18;
        uint256 deadline = type(uint256).max;

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, bytes32(0));

        vm.prank(spender);
        vm.expectRevert("ERC20Permit: invalid signature");
        token.permit(ownerAddr, spender, value, deadline, v, r, s);
    }
}
