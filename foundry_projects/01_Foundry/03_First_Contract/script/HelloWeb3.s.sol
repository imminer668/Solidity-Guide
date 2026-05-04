// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Script.sol";
import "src/HelloWeb3.sol";

contract HelloWeb3Script is Script {
    function run() external {
        vm.startBroadcast();

        HelloWeb3 hello = new HelloWeb3();
        console.log("Contract deployed at:", address(hello));

        vm.stopBroadcast();
    }
}
