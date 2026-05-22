// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../../src/raw/ERC20.sol";
import {Airdrop} from "../../src/raw/Airdrop.sol";

/**
 * @title AirdropRawTest
 * @notice 原生实现 Airdrop（空投）的单元测试
 * @dev 教学重点：
 *      1. Airdrop 用批量转账节省 gas：单次调用发给多人
 *      2. 既支持 ERC20 空投（multiTransferToken），也支持 ETH 空投（multiTransferETH）
 *      3. 长度校验：addresses 和 amounts 必须等长，否则 revert
 *      4. {value: X ether} 配合 payable 函数附带 ETH
 */
contract AirdropRawTest is Test {
    ERC20 public token;
    Airdrop public airdrop;
    address payable public user1 = payable(address(1));
    address payable public user2 = payable(address(2));
    address public user3 = address(3);

    /// @dev 部署后铸 10000 token，并授权 airdrop 合约可支配
    function setUp() public {
        token = new ERC20("Test Token", "TEST");
        airdrop = new Airdrop();
        token.mint(10000);
        token.approve(address(airdrop), 10000);
    }

    /// @notice 验证 ERC20 批量转账：每个地址收到对应 amount
    function testMultiTransferToken() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        airdrop.multiTransferToken(address(token), addresses, amounts);
        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(user2), 200);
    }

    /// @notice 验证 addresses/amounts 长度不一致必须 revert
    /// @dev 教学要点：长度校验是 airdrop 类合约最常见的安全检查
    function testMultiTransferTokenLengthMismatch() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user2;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        vm.expectRevert("Lengths of Addresses and Amounts NOT EQUAL");
        airdrop.multiTransferToken(address(token), addresses, amounts);
    }

    /// @notice 验证 ETH 批量转账：{value: 3 ether} 配合 payable 函数
    function testMultiTransferETH() public {
        address payable[] memory addresses = new address payable[](2);
        addresses[0] = user1;
        addresses[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 1 ether;
        amounts[1] = 2 ether;

        airdrop.multiTransferETH{value: 3 ether}(addresses, amounts);
        assertEq(user1.balance, 1 ether);
        assertEq(user2.balance, 2 ether);
    }

    /// @notice 验证内部工具函数 getSum 用于校验总金额
    /// @dev 教学要点：airdrop 通常在批量转账前用 getSum 校验 msg.value == sum(amounts)
    function testGetSum() public {
        uint256[] memory arr = new uint256[](3);
        arr[0] = 100;
        arr[1] = 200;
        arr[2] = 300;
        assertEq(airdrop.getSum(arr), 600);
    }
}
