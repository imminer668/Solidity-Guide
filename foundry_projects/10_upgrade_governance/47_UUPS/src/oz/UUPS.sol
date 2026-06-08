// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev UUPS 逻辑合约 V1（OpenZeppelin 实现）
 * 继承 UUPSUpgradeable 提供可升级能力
 * 状态变量顺序与代理合约保持一致以避免存储槽冲突
 */
contract UUPSLogicV1OZ is Initializable, UUPSUpgradeable {
    address public admin;
    string public words;

    function initialize(address _admin) public initializer {
        admin = _admin;
        words = "old";
    }

    function foo() public {
        words = "old v1";
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

    function getWords() public view returns (string memory) {
        return words;
    }
}

/**
 * @dev UUPS 逻辑合约 V2（OpenZeppelin 实现）
 */
contract UUPSLogicV2OZ is Initializable, UUPSUpgradeable {
    address public admin;
    string public words;

    function initialize(address _admin) public initializer {
        admin = _admin;
        words = "new";
    }

    function foo() public {
        words = "new v2";
    }

    function _authorizeUpgrade(address newImplementation) internal override {}

    function getWords() public view returns (string memory) {
        return words;
    }
}