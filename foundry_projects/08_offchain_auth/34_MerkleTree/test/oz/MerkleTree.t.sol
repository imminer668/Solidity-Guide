// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {MerkleTreeOZ} from "../../src/oz/MerkleTree.sol";

/**
 * @title MerkleTreeOZTest
 * @notice 基于 OZ 模式实现的 MerkleTree 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版继承 OZ 的 ERC721，并自动 emit 标准事件
 *      - MerkleProof 验证逻辑保持一致
 *      - 构造时附 name/symbol，便于浏览器识别
 */
contract MerkleTreeOZTest is Test {
    bytes32 public root = 0xeeefd63003e0e702cb41cd0043015a6e26ddb38073cc6ffeb0ba3e808ba8c097;
    address public user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;

    MerkleTreeOZ public merkleTree;

    /// @dev 部署时附 name/symbol
    function setUp() public {
        merkleTree = new MerkleTreeOZ(root, "F1 MerkleTree", "F1");
    }

    /// @notice 验证用有效 proof 铸造
    function testMintWithValidProof() public {
        bytes32[] memory proof = new bytes32[](2);
        proof[0] = 0x999bf57501565dbd2fdcea36efa2b9aef8340a8901e3459f4a4c926275d36cdb;
        proof[1] = 0x4726e4102af77216b09ccd94f40daa10531c87c4d60bba7f3b3faf5ff9f19b3c;

        merkleTree.mint(user1, 0, proof);
        assertEq(merkleTree.ownerOf(0), user1);
    }

    /// @notice 验证无效 proof 必须 revert
    function testMintWithInvalidProof() public {
        bytes32[] memory proof = new bytes32[](1);
        proof[0] = 0x0000000000000000000000000000000000000000000000000000000000000001;

        vm.expectRevert("Invalid merkle proof");
        merkleTree.mint(user1, 0, proof);
    }
}
