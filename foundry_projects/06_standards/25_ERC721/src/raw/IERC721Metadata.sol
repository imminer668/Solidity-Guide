// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC721} from "./IERC721.sol";

/**
 * @dev ERC721 元数据扩展接口
 */
interface IERC721Metadata is IERC721 {
    function name() external view returns (string memory);
    function symbol() external view returns (string memory);
    function tokenURI(uint256 tokenId) external view returns (string memory);
}