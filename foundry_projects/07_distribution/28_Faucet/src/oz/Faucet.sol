// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Faucet} from "../../src/raw/Faucet.sol";

/**
 * @dev OpenZeppelin 代币水龙头实现
 */
contract FaucetOZ {
    uint256 public amountAllowed = 100;
    ERC20 public token;
    mapping(address => bool) public requestedAddress;

    event SendToken(address indexed Receiver, uint256 indexed Amount);

    constructor(ERC20 _token) {
        token = _token;
    }

    function requestTokens() external {
        require(!requestedAddress[msg.sender], "Can't Request Multiple Times!");
        require(token.balanceOf(address(this)) >= amountAllowed, "Faucet Empty!");

        token.transfer(msg.sender, amountAllowed);
        requestedAddress[msg.sender] = true;
        emit SendToken(msg.sender, amountAllowed);
    }
}