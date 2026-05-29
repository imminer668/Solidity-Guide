// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20Permit} from "../../src/raw/ERC20Permit.sol";

/**
 * @dev OpenZeppelin ERC20Permit 实现
 */
contract ERC20PermitOZ is ERC20Permit {
    constructor(string memory name, string memory symbol) ERC20Permit(name, symbol) {}
}