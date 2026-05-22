// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "./IERC20.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev Pull 模式空投(Merkle Tree 版)
 *
 * 与 29 课正文 push 模式(multiTransferToken)的区别:
 *   - push 模式:项目方一次循环,挨个 transfer;失败记 failList
 *   - pull 模式:白名单 + 总量一次性 deposit;用户自己来 claim,带 Merkle proof
 *
 * 适用场景:白名单人数极多(几十万上百万),push 模式循环会 OOG
 *          拉链上只做"轻验证 + 转账",不在链上算白名单
 */
contract MerkleAirdrop {
    IERC20 public immutable token;
    bytes32 public immutable merkleRoot;

    mapping(address => bool) public claimed;

    event Claimed(address indexed claimant, uint256 amount);

    error AlreadyClaimed();
    error InvalidProof();
    error TransferFailed();

    constructor(IERC20 _token, bytes32 _merkleRoot) {
        token = _token;
        merkleRoot = _merkleRoot;
    }

    function claim(uint256 amount, bytes32[] calldata proof) external {
        if (claimed[msg.sender]) revert AlreadyClaimed();

        bytes32 leaf = keccak256(abi.encodePacked(msg.sender, amount));
        if (!MerkleProof.verify(proof, merkleRoot, leaf)) revert InvalidProof();

        claimed[msg.sender] = true;
        emit Claimed(msg.sender, amount);

        bool ok = token.transfer(msg.sender, amount);
        if (!ok) revert TransferFailed();
    }
}
