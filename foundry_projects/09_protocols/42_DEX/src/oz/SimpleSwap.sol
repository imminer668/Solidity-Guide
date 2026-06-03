// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {SimpleSwap as SimpleSwapRaw, IERC20} from "../../src/raw/SimpleSwap.sol";

/**
 * @dev SimpleSwap OpenZeppelin 实现
 */
contract SimpleSwapOZ is SimpleSwapRaw {
    constructor(IERC20 _token0, IERC20 _token1) SimpleSwapRaw(_token0, _token1) {}
}