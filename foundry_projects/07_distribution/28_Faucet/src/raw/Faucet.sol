// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {IERC20} from "./IERC20.sol";

/**
 * @dev 代币水龙头合约 - 原生实现
 * 用户可以领取一次免费代币
 */
contract Faucet {
    uint256 public amountAllowed = 100;
    address public tokenContract;
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(address _tokenContract) {
        tokenContract = _tokenContract;
    }

    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        IERC20 token = IERC20(tokenContract);
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}