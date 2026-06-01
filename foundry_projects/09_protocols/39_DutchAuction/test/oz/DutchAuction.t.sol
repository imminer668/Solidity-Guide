// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {DutchAuctionOZ} from "../../src/oz/DutchAuction.sol";

/**
 * @title DutchAuctionOZTest
 * @notice 基于 OZ 模式实现的 DutchAuction 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版继承 ERC721，更安全（完备的 NFT 接口 + 事件）
 *      - 拍卖衰减逻辑保持一致
 *      - 业务行为等价
 */
contract DutchAuctionOZTest is Test {
    DutchAuctionOZ public auction;

    function setUp() public {
        auction = new DutchAuctionOZ();
    }

    /// @notice 验证初始状态
    function testInitialState() public view {
        assertEq(auction.auctionStartTime(), block.timestamp);
        assertEq(auction.totalSupply(), 0);
    }

    /// @notice 验证初始拍卖价
    function testGetAuctionPrice() public view {
        uint256 price = auction.getAuctionPrice();
        assertEq(price, 1 ether);
    }

    /// @notice 验证正常铸造
    function testAuctionMint() public {
        uint256 price = auction.getAuctionPrice();
        uint256 quantity = 1;
        uint256 totalCost = price * quantity;

        vm.deal(address(this), totalCost);
        auction.auctionMint{value: totalCost}(quantity);

        assertEq(auction.totalSupply(), quantity);
    }
}
