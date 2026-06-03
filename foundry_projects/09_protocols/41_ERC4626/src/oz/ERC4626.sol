// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {ERC4626 as RawERC4626} from "../raw/ERC4626.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev ERC4626 OpenZeppelin wrapper (re-exports raw implementation for tutorial consistency)
 */
contract ERC4626 is RawERC4626 {
    constructor(
        ERC20 asset_,
        string memory name_,
        string memory symbol_
    ) RawERC4626(asset_, name_, symbol_) {}
}