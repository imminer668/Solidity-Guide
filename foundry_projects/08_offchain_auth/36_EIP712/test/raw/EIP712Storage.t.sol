// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {EIP712Storage} from "../../src/raw/EIP712Storage.sol";

/**
 * @title EIP712StorageRawTest
 * @notice 原生实现 EIP-712 类型化结构签名的单元测试
 * @dev 教学重点：
 *      1. EIP-712 是"结构化签名"标准：让用户看到可读的字段名而非 hex
 *      2. 关键概念：
 *         - DOMAIN_SEPARATOR: 区分不同 dapp/链上的签名
 *         - typeHash: keccak256(类型字符串)，如 "Storage(address,uint256)"
 *         - structHash: keccak256(abi.encode(typeHash, params...))
 *         - digest: keccak256("\x19\x01" ++ domainSeparator ++ structHash)
 *      3. permit 模式：链下签名授权，链上一次交易完成"授权+转账"
 *      4. vm.addr(privateKey) 从私钥派生地址；vm.sign(pk, digest) 签名
 *
 *      本项目演示一个"代签名修改存储"的小应用：owner 离线签名，
 *      spender 持签名调用 permitStore 修改 number
 */
contract EIP712StorageRawTest is Test {
    EIP712Storage public storageContract;
    /// @dev owner 私钥（公开，仅用于测试）
    uint256 public ownerPrivateKey = 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b;
    address public ownerAddr;

    /// @dev 部署时设置 ownerAddr
    function setUp() public {
        ownerAddr = vm.addr(ownerPrivateKey);
        storageContract = new EIP712Storage(ownerAddr);
    }

    /// @notice 验证初始 number 为 0
    /// @dev 教学要点：view 函数用 public view 修饰，既省 gas 又能直接调用
    function testInitialNumber() public view {
        assertEq(storageContract.retrieve(), 0);
    }

    /// @notice 验证有效签名可修改存储
    /// @dev 教学要点：
    ///      1. digest = keccak256("\x19\x01" ++ DOMAIN_SEPARATOR ++ structHash)
    ///      2. abi.encode（非 packed）用于 structHash 拼接，与 EIP-712 规范一致
    ///      3. vm.prank(address(this)) 让 permitStore 的 msg.sender = test contract
    ///         因为 permit 内部会用 msg.sender 作为 spender
    function testPermitStoreWithValidSignature() public {
        uint256 newNum = 100;
        bytes32 domainSeparator = storageContract.DOMAIN_SEPARATOR();
        bytes32 typeHash = keccak256("Storage(address spender,uint256 number)");

        // spender = address(this) ：因为 permitStore 内部会从 msg.sender 提取 spender
        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            domainSeparator,
            keccak256(abi.encode(typeHash, address(this), newNum))
        ));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPrivateKey, digest);
        bytes memory signature = abi.encodePacked(r, s, bytes1(v));

        vm.prank(address(this));
        storageContract.permitStore(newNum, signature);
        assertEq(storageContract.retrieve(), newNum);
    }

    /// @notice 验证伪造签名必须 revert
    function testPermitStoreWithInvalidSignature() public {
        bytes memory fakeSignature = new bytes(65);
        vm.prank(address(this));
        vm.expectRevert("EIP712Storage: Invalid signature");
        storageContract.permitStore(100, fakeSignature);
    }
}
