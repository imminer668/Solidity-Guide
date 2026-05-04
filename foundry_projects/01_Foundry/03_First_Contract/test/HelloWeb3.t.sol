// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/HelloWeb3.sol";

contract HelloWeb3Test is Test {
    HelloWeb3 public hello;

    function setUp() public {
        hello = new HelloWeb3();
    }

    function testGreetingValue() public {
        // 验证 greeting 变量的值是 "Hello Web3!"
        assertEq(hello.greeting(), "Hello Web3!");
    }

    function testGetGreeting() public {
        // 验证 getGreeting() 函数返回值
        assertEq(hello.getGreeting(), "Hello Web3!");
    }

    function testGreetingIsPublic() public {
        // 验证 greeting 是 public 的，任何人都能通过合约读取
        string memory retrieved = hello.greeting();
        assertEq(retrieved, "Hello Web3!");
    }
}
