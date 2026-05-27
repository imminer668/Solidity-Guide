// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {MerkleProof} from "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

/**
 * @dev OpenZeppelin MerkleTree 合约
 */
contract MerkleTreeOZ is ERC721 {
    bytes32 public immutable root;
    mapping(address => bool) public mintedAddress;

    constructor(bytes32 merkleroot, string memory name, string memory symbol) ERC721(name, symbol) {
        root = merkleroot;
    }

    function mint(address account, uint256 tokenId, bytes32[] calldata proof) external {
        require(_verify(_leaf(account), proof), "Invalid merkle proof");
        require(!mintedAddress[account], "Already minted!");

        mintedAddress[account] = true;
        _mint(account, tokenId);
    }

    function _leaf(address account) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(account));
    }

    function _verify(bytes32 leaf, bytes32[] memory proof) internal view returns (bool) {
        return MerkleProof.verify(proof, root, leaf);
    }
}