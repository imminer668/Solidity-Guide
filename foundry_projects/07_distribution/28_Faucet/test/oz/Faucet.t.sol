// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Minter} from "../../src/oz/ERC20Minter.sol";
import {FaucetOZ} from "../../src/oz/Faucet.sol";

/**
 * @title FaucetOZTest
 * @notice 基于 OZ 模式实现的 Faucet 单元测试
 * @dev 与 raw 对比：
 *      - 资金来源更灵活：可直接 mint(address(faucet), 10000) 给水龙头充值
 *      - 仍保留"单地址限领一次"的反女巫机制
 *      - 与 raw 行为等价，业务语义保持一致
 */
contract FaucetOZTest is Test {
    ERC20Minter public token;
    FaucetOZ public faucet;

    /// @dev OZ 版本通过 ERC20Minter 直接 mint 给 faucet，无需 transfer
    function setUp() public {
        token = new ERC20Minter("Test Token", "TEST");
        faucet = new FaucetOZ(token);
        token.mint(address(faucet), 10000);
    }

    /// @notice 验证首次领取成功，并被标记已领
    function testRequestToken() public {
        faucet.requestTokens();
        assertEq(token.balanceOf(address(this)), 100);
        assertTrue(faucet.requestedAddress(address(this)));
    }

    /// @notice 验证同一地址重复领取必须 revert
    function testRequestTokenOnlyOnce() public {
        faucet.requestTokens();
        vm.expectRevert("Can't Request Multiple Times!");
        faucet.requestTokens();
    }
}
