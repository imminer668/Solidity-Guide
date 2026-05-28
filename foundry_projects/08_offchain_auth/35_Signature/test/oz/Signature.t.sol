// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SignatureNFTOZ} from "../../src/oz/SignatureNFT.sol";

/**
 * @title SignatureOZTest
 * @notice 基于 OZ 模式实现的 ECDSA 签名白名单铸造单元测试
 * @dev 与 raw 对比：
 *      - OZ 版用 ECDSA.recover 替代内联 ecrecover，更安全（含 malleability 检查）
 *      - 业务行为等价
 *      - 构造时附 name/symbol
 */
contract SignatureOZTest is Test {
    address public signer = 0xe16C1623c1AA7D919cd2241d8b36d9E79C1Be2A2;
    address public user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    SignatureNFTOZ public signatureNft;

    /// @dev 部署时锁定 signer 并附 name/symbol
    function setUp() public {
        signatureNft = new SignatureNFTOZ(signer, "F1 Signature", "F1");
    }

    /// @notice 验证有效签名铸造
    /// @dev 流程与 raw 一致：getMessageHash -> 加前缀 -> vm.sign -> 提交
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
}
