// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @dev SimpleUpgrade OpenZeppelin 实现
 * 使用 OpenZeppelin 的 TransparentUpgradeableProxy
 */
contract SimpleUpgradeOZ is TransparentUpgradeableProxy {
    constructor(address implementation_, bytes memory _data) TransparentUpgradeableProxy(implementation_, msg.sender, _data) {}
}