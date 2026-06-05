// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Proxy} from "../../src/raw/Proxy.sol";

/**
 * @dev Proxy OpenZeppelin 实现
 */
contract ProxyOZ is Proxy {
    constructor(address implementation_) Proxy(implementation_) {}
}