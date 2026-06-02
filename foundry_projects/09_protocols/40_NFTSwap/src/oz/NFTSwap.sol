// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {NFTSwap as NFTSwapRaw} from "../../src/raw/NFTSwap.sol";

/**
 * @dev NFTSwap OpenZeppelin 实现
 */
contract NFTSwapOZ is NFTSwapRaw {
    constructor() NFTSwapRaw() {}
}