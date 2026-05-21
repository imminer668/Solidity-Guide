// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC165} from "./IERC165.sol";

/**
 * @dev ERC1155 接收者接口
 */
interface IERC1155Receiver is IERC165 {
    function onERC1155Received(
        address operator,
        address from,
        uint256 id,
        uint256 value,
        bytes calldata data
    ) external returns (bytes4);

    function onERC1155BatchReceived(
        address operator,
        address from,
        uint256[] calldata ids,
        uint256[] calldata values,
        bytes calldata data
    ) external returns (bytes4);
}