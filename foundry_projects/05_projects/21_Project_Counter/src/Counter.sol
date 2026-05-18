// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Counter {
    uint256 public count;
    address public owner;

    event CountIncremented(uint256 newValue);
    event CountDecremented(uint256 newValue);
    event CountReset();

    constructor() {
        owner = msg.sender;
        count = 0;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function increment() external {
        count++;
        emit CountIncremented(count);
    }

    function decrement() external onlyOwner {
        require(count > 0, "Count is zero");
        count--;
        emit CountDecremented(count);
    }

    function reset() external onlyOwner {
        count = 0;
        emit CountReset();
    }
}