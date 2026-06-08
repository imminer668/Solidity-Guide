// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

/**
 * @dev TransparentProxy OpenZeppelin 实现
 * 使用 OpenZeppelin 的透明代理合约
 */
contract TransparentProxyOZ is TransparentUpgradeableProxy {
    constructor(address implementation_, bytes memory _data) TransparentUpgradeableProxy(implementation_, msg.sender, _data) {}
}