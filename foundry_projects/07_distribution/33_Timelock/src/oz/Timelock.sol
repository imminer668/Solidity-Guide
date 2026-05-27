// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Timelock} from "../../src/raw/Timelock.sol";

/**
 * @dev OpenZeppelin 时间锁合约
 */
contract TimelockOZ is Timelock {
    constructor(uint delay_) Timelock(delay_) {}
}