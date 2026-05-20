// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";

/**
 * @dev OpenZeppelin ERC721 实现
 */
contract NFTToken is ERC721 {
    uint256 public maxSupply;

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 maxSupply_
    ) ERC721(name_, symbol_) {
        maxSupply = maxSupply_;
    }

    function mint(address to, uint256 tokenId) external {
        require(tokenId < maxSupply, "tokenId out of range");
        _mint(to, tokenId);
    }

    function _baseURI() internal view override returns (string memory) {
        return "ipfs://QmeSjSinHpPnmXmspMjwiXyN6zS4E9zccariGR3jxcaWtq/";
    }
}