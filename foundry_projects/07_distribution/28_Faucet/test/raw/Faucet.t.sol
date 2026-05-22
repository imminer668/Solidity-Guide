// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20} from "../../src/raw/ERC20.sol";
import {Faucet} from "../../src/raw/Faucet.sol";

/**
 * @title FaucetRawTest
 * @notice 原生实现 Faucet（测试网水龙头）的单元测试
 * @dev 教学重点：
 *      1. Faucet 是项目方空投代币给早期用户的常见入口
 *      2. 每个地址仅能领一次（防女巫攻击）
 *      3. Faucet 自身需要持有代币余额，发完即空
 *
 *      Foundry 技巧：vm.prank(addr) 让下一次调用以 addr 作为 msg.sender
 */
contract FaucetRawTest is Test {
    ERC20 public token;
    Faucet public faucet;
    address public user1 = address(1);
    address public user2 = address(2);
    address public user3 = address(3);

    /// @dev 部署后铸 250 token，全部转给 faucet，模拟"装满水龙头"
    function setUp() public {
        token = new ERC20("Test Token", "TEST");
        faucet = new Faucet(address(token));
        token.mint(250);
        token.transfer(address(faucet), 250);
    }

    /// @notice 验证正常领取：测试合约领取 100 token，并被标记
    /// @dev 教学要点：Faucet 内部用 mapping(address=>bool) 记录已领取地址
    function testRequestToken() public {
        faucet.requestTokens();
        assertEq(token.balanceOf(address(this)), 100);
        assertTrue(faucet.requestedAddress(address(this)));
    }

    /// @notice 验证同一地址不能重复领取
    /// @dev 教学要点：vm.expectRevert("字符串") 校验 revert reason 必须完全一致
    function testRequestTokenOnlyOnce() public {
        faucet.requestTokens();
        vm.expectRevert("Can't Request Multiple Times!");
        faucet.requestTokens();
    }

    /// @notice 验证水龙头资金耗尽时必须 revert
    /// @dev 教学要点：测试中模拟了三个不同地址依次领取，第三个因余额不足而失败
    function testFaucetEmpty() public {
        vm.prank(user1);
        faucet.requestTokens();
        vm.prank(user2);
        faucet.requestTokens();
        assertEq(token.balanceOf(user1), 100);
        assertEq(token.balanceOf(user2), 100);
        vm.prank(user3);
        vm.expectRevert("Faucet Empty!");
        faucet.requestTokens();
    }
}
