// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev ERC721 接收者接口
 * 合约必须实现此接口来通过安全转账接收 ERC721
 */
interface IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4);
}