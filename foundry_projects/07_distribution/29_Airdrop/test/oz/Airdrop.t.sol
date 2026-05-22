// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Minter} from "../../src/oz/ERC20Minter.sol";
import {AirdropOZ} from "../../src/oz/Airdrop.sol";

/**
 * @title AirdropOZTest
 * @notice 基于 OZ 模式实现的 Airdrop 单元测试
 * @dev 与 raw 对比：
 *      - 资金通过 ERC20Minter 铸造给测试合约（msg.sender）
 *      - 测试合约作为授权方，将额度给到 airdrop 合约
 *      - 业务行为与 raw 完全等价
 */
contract AirdropOZTest is Test {
    ERC20Minter public token;
    AirdropOZ public airdrop;
    address payable public user1 = payable(address(1));
    address payable public user2 = payable(address(2));

    /// @dev OZ 版依赖 mint 给测试合约 + 授权给 airdrop
    function setUp() public {
        token = new ERC20Minter("Test Token", "TEST");
        airdrop = new AirdropOZ();
        token.mint(address(this), 10000);
        token.approve(address(airdrop), 10000);
    }

    /// @notice 验证 ERC20 批量转账
    function testMultiTransferToken() public {
        address[] memory addresses = new address[](2);
        addresses[0] = user1;
        addresses[1] = user2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;

        airdrop.multiTransferToken(token, addresses, amounts);
        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(user2), 200);
    }

    /// @notice 验证 ETH 批量转账
    /// @dev {value: 3 ether} 必须等于 sum(amounts)，否则 airdrop 内 getSum 校验会失败
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
}
