// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {DutchAuction as DutchAuctionRaw} from "../../src/raw/DutchAuction.sol";

/**
 * @dev DutchAuction OpenZeppelin 实现
 */
contract DutchAuctionOZ is DutchAuctionRaw {
    constructor() DutchAuctionRaw() {}
}