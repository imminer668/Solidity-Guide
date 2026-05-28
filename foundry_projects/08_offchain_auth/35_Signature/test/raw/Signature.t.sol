// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SignatureNFT} from "../../src/raw/SignatureNFT.sol";

/**
 * @title SignatureRawTest
 * @notice 原生实现 ECDSA 签名白名单铸造的单元测试
 * @dev 教学重点：
 *      1. ECDSA 签名白名单：项目方链下签名，用户链上提交
 *      2. 流程：project 端 sign(ethHash) -> 用户拿 (v,r,s) -> 合约用 ecrecover 验证
 *      3. 必须用 "\x19Ethereum Signed Message:\n32" 前缀以防重放攻击
 *      4. vm.sign(privateKey, digest) 是 Foundry cheatcode，可在测试中"造"签名
 *
 *      与 MerkleTree 的区别：
 *      - MerkleTree：一次性把 root 上链，后续铸造只需提交 proof（O(log n)）
 *      - Signature：项目方对每个用户单独签名（O(1) 验证，O(n) 链下签名成本）
 */
contract SignatureRawTest is Test {
    /// @dev 项目方 signer 地址
    address public signer = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
    address public user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    SignatureNFT public signatureNft;

    /// @dev 部署时锁定 signer
    function setUp() public {
        signatureNft = new SignatureNFT(signer);
    }

    /// @notice 验证有效签名可铸造
    /// @dev 教学要点：
    ///      1. msgHash = keccak256(abi.encodePacked(user, tokenId))，包含铸造参数
    ///      2. ethHash = keccak256("\x19Ethereum Signed Message:\n32" ++ msgHash)
    ///         必须用以太坊签名前缀，避免跨应用重放
    ///      3. (v, r, s) 是 ECDSA 签名三元组，r/s 拼 64 字节，v 拼 1 字节
    function testMintWithValidSignature() public {
        bytes32 msgHash = signatureNft.getMessageHash(user1, 0);
        bytes32 ethHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(0x227dbb8586117d55284e26620bc76534dfbd2394be34cf4a09cb775d593b6f2b, ethHash);
        bytes memory signature = abi.encodePacked(r, s, bytes1(v));

        signatureNft.mint(user1, 0, signature);
        assertEq(signatureNft.ownerOf(0), user1);
    }

    /// @notice 验证伪造签名必须 revert
    function testMintWithInvalidSignature() public {
        bytes memory fakeSignature = new bytes(65);
        vm.expectRevert("Invalid signature");
        signatureNft.mint(user1, 0, fakeSignature);
    }
}
