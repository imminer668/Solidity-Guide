// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @dev OpenZeppelin 空投合约
 */
contract AirdropOZ {
    mapping(address => uint256) public failTransferList;

    function multiTransferToken(
        ERC20 token,
        address[] calldata _addresses,
        uint256[] calldata _amounts
    ) external {
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint256 _amountSum = getSum(_amounts);
        require(token.allowance(msg.sender, address(this)) >= _amountSum, "Need Approve ERC20 token");

        for (uint256 i; i < _addresses.length; i++) {
            token.transferFrom(msg.sender, _addresses[i], _amounts[i]);
        }
    }

    function multiTransferETH(
        address payable[] calldata _addresses,
        uint256[] calldata _amounts
    ) external payable {
        require(_addresses.length == _amounts.length, "Lengths of Addresses and Amounts NOT EQUAL");
        uint256 _amountSum = getSum(_amounts);
        require(msg.value == _amountSum, "Transfer amount error");

        for (uint256 i = 0; i < _addresses.length; i++) {
            (bool success,) = _addresses[i].call{value: _amounts[i]}("");
            if (!success) {
                failTransferList[_addresses[i]] = _amounts[i];
            }
        }
    }

    function getSum(uint256[] calldata _arr) public pure returns (uint256 sum) {
        for (uint256 i = 0; i < _arr.length; i++) sum = sum + _arr[i];
    }
}