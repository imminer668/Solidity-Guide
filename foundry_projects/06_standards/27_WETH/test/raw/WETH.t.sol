// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {WETH} from "../../src/raw/WETH.sol";

/**
 * @title WETHRawTest
 * @notice 原生实现 WETH9 的单元测试
 * @dev 教学重点：
 *      1. WETH = Wrapped ETH，将原生 ETH 包装为 ERC20 代币
 *      2. deposit() 接收 ETH 并铸造等量 WETH；withdraw() 销毁 WETH 退回 ETH
 *      3. receive() / fallback() 同样支持存款（直接 send ETH 到合约地址）
 *      4. WETH9 是 DeFi 基础设施，被 Uniswap V2、Aave 等众多协议采用
 */
contract WETHRawTest is Test {
    WETH public weth;

    /// @dev 测试合约默认地址持有测试用 ETH（Foundry 自带 cheatcode 处理）
    function setUp() public {
        weth = new WETH();
    }

    /// @notice 验证 deposit 后 WETH 余额等于存入的 ETH
    /// @dev {value: 1 ether} 是 Solidity 调用语法，附带 ETH 给目标函数
    function testDeposit() public {
        weth.deposit{value: 1 ether}();
        assertEq(weth.balanceOf(address(this)), 1 ether);
    }

    /// @notice 验证 totalSupply 与 deposit 同步增长
    function testTotalSupply() public {
        weth.deposit{value: 1 ether}();
        assertEq(weth.totalSupply(), 1 ether);
    }

    /// @notice 验证 fallback 函数：向合约地址直接 send ETH 也能存款
    /// @dev 教学要点：fallback 在调用不存在的函数时被触发
    function testFallbackDeposit() public {
        address(weth).call{value: 0.5 ether}("");
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
    }

    /// @notice 验证 receive 函数：带空 calldata 的 ETH 转账
    /// @dev 教学要点：receive 是 receive() external payable，专门处理纯转账
    function testReceiveDeposit() public {
        (bool success,) = address(weth).call{value: 0.5 ether}("");
        require(success);
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
    }

    /// @notice 验证 WETH 作为 ERC20 一样可以转账
    function testTransfer() public {
        weth.deposit{value: 1 ether}();
        weth.transfer(address(2), 0.5 ether);
        assertEq(weth.balanceOf(address(this)), 0.5 ether);
        assertEq(weth.balanceOf(address(2)), 0.5 ether);
    }

    /// @notice 验证 approve + transferFrom 流程
    /// @dev 教学要点：vm.prank(address(2)) 让 address(2) 成为下一次调用的 msg.sender
    function testApproveAndTransferFrom() public {
        weth.deposit{value: 1 ether}();
        weth.approve(address(2), 0.5 ether);
        vm.prank(address(2));
        weth.transferFrom(address(this), address(2), 0.5 ether);
        assertEq(weth.balanceOf(address(2)), 0.5 ether);
    }
}
