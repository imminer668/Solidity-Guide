// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {EIP712Storage} from "../../src/raw/EIP712Storage.sol";

/**
 * @dev OpenZeppelin EIP712Storage 实现
 */
contract EIP712StorageOZ is EIP712Storage {
    constructor(address _owner) EIP712Storage(_owner) {}
}