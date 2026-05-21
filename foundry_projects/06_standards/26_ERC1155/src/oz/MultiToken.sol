// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

/**
 * @dev OpenZeppelin ERC1155 实现
 */
contract MultiToken is ERC1155 {
    uint256 public constant MAX_ID = 10000;

    constructor(string memory uri_) ERC1155(uri_) {}

    function mint(address to, uint256 id, uint256 amount) external {
        require(id < MAX_ID, "id overflow");
        _mint(to, id, amount, "");
    }

    function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts) external {
        for (uint256 i = 0; i < ids.length; i++) {
            require(ids[i] < MAX_ID, "id overflow");
        }
        _mintBatch(to, ids, amounts, "");
    }
}