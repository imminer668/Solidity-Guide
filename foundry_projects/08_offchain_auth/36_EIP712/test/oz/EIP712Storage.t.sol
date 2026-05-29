// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {EIP712StorageOZ} from "../../src/oz/EIP712Storage.sol";

/**
 * @title EIP712StorageOZTest
 * @notice 基于 OZ 模式实现的 EIP-712 签名单元测试
 * @dev 与 raw 对比：
 *      - 继承 OZ 的 EIP712 后，_domainSeparatorV4() 由 OZ 实现
 *      - digest 计算与 raw 完全相同："\x19\x01" + domainSeparator + structHash
 *      - 业务行为等价
 */
contract EIP712StorageOZTest is Test {
    EIP712StorageOZ public storageContract;
    uint256 public ownerPrivateKey = 0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b;
    address public ownerAddr;

    function setUp() public {
        ownerAddr = vm.addr(ownerPrivateKey);
        storageContract = new EIP712StorageOZ(ownerAddr);
    }

    /// @notice 验证初始值为 0
    function testInitialNumber() public view {
        assertEq(storageContract.retrieve(), 0);
    }

    /// @notice 验证有效签名可修改存储
    /// @dev 流程：构造 digest -> vm.sign 签名 -> vm.prank 模拟 spender -> permitStore
    function testPermitStoreWithValidSignature() public {
        uint256 newNum = 100;
        bytes32 domainSeparator = storageContract.DOMAIN_SEPARATOR();
        bytes32 typeHash = keccak256("Storage(address spender,uint256 number)");

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
}
