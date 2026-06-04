// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SimpleFlashloanOZ} from "../../src/oz/Flashloan.sol";
import {MockERC20} from "../../src/raw/Flashloan.sol";

/**
 * @title FlashloanOZTest
 * @notice 基于 OZ 模式实现的 Flashloan 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版采用 OZ 推荐的 SafeERC20、ReentrancyGuard
 *      - 接口保持一致：flashloan(token, amount, data)
 *      - 业务行为等价
 */
contract FlashloanOZTest is Test {
    SimpleFlashloanOZ public flashloan;
    MockERC20 public token;

    /// @dev OZ 版部署无参数，mock token 与 raw 共用
    function setUp() public {
        flashloan = new SimpleFlashloanOZ();
        token = new MockERC20("Mock Token", "MOCK");
        token.mint(address(flashloan), 1000e18);
    }

    /// @notice 验证初始流动性
    function testInitialState() public view {
        assertEq(token.balanceOf(address(flashloan)), 1000e18);
    }
}
