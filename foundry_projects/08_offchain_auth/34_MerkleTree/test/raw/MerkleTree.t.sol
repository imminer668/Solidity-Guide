// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {MerkleTree} from "../../src/raw/MerkleTree.sol";
import {MerkleProof} from "../../src/raw/MerkleProof.sol";

/**
 * @title MerkleTreeRawTest
 * @notice 原生实现 MerkleTree 白名单铸造的单元测试
 * @dev 教学重点：
 *      1. Merkle Tree 白名单是把所有白名单地址的 leaf 哈希成一棵二叉树
 *      2. 部署时只把 root 写入合约，节省存储成本
 *      3. 用户提供 (address, tokenId) 的 leaf 和 proof，合约可本地验证
 *      4. MerkleProof.verify 是 OZ 标准的 verify 函数，被广泛使用
 *
 *      数据来源：教程配套脚本生成的固定 root/leaf/proof
 */
contract MerkleTreeRawTest is Test {
    /// @dev 教程预设的 root：所有白名单地址的 merkle root
    bytes32 public root = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097;
    /// @dev 白名单用户地址
    address public user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public user2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;

    MerkleTree public merkleTree;

    /// @dev 部署时仅传入 root
    function setUp() public {
        merkleTree = new MerkleTree(root);
    }

    /// @notice 验证用有效 proof 铸造后所有权归 user1
    /// @dev 教学要点：proof 数组是 leaf 到 root 的兄弟节点路径
    function testMintWithValidProof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
        proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;

        merkleTree.mint(user1, 0, proof);
        assertEq(merkleTree.ownerOf(0), user1);
    }

    /// @notice 验证伪造的 proof 必须 revert
    function testMintWithInvalidProof() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x0000000000000000000000000000000000000000000000000000000000000001;

        vm.expectRevert("Invalid merkle proof");
        merkleTree.mint(user1, 0, proof);
    }

    /// @notice 验证同一地址同一 tokenId 重复铸造必须 revert
    /// @dev 教学要点：bitmap/mapping 记录已 mint 状态，防止双花
    function testCannotMintTwice() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
        proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;

        merkleTree.mint(user1, 0, proof);
        vm.expectRevert("Already minted!");
        merkleTree.mint(user1, 1, proof);
    }

    /// @notice 直接验证 MerkleProof 库函数
    /// @dev 教学要点：MerkleProof.verify 是纯函数，可独立测试
    function testMerkleProofVerify() public {
        bytes32 leaf = keccak256(abi.encodePacked(user1));
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
        proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;

        assertTrue(MerkleProof.verify(proof, root, leaf));
    }
}
