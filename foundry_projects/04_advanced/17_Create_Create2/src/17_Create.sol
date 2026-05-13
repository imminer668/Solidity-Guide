// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract Pair {
    address public factory;
    address public token0;
    address public token1;

    constructor(address _token0, address _token1) {
        factory = msg.sender;
        token0 = _token0;
        token1 = _token1;
    }

    function initialize(address _token0, address _token1) external {
        require(msg.sender == factory, "Forbidden");
        token0 = _token0;
        token1 = _token1;
    }
}

contract PairFactory {
    mapping(address => mapping(address => address)) public getPair;
    address[] public allPairs;

    function createPair(address tokenA, address tokenB) external returns (address pairAddr) {
        Pair pair = new Pair(tokenA, tokenB);
        pair.initialize(tokenA, tokenB);
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }

    // Create2 版本
    function createPair2(address tokenA, address tokenB, bytes32 salt) external returns (address pairAddr) {
        Pair pair = new Pair{salt: salt}(tokenA, tokenB);
        pair.initialize(tokenA, tokenB);
        pairAddr = address(pair);
        allPairs.push(pairAddr);
        getPair[tokenA][tokenB] = pairAddr;
        getPair[tokenB][tokenA] = pairAddr;
    }
}
