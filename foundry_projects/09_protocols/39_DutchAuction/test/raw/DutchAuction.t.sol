// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {DutchAuction} from "../../src/raw/DutchAuction.sol";

/**
 * @title DutchAuctionRawTest
 * @notice 原生实现 DutchAuction（荷兰式拍卖）的单元测试
 * @dev 教学重点：
 *      1. 荷兰式拍卖：价格随时间线性下降，先到先得
 *         - 起始价最高，随时间衰减到地板价
 *         - 越晚买入越便宜，鼓励早期参与
 *      2. 关键字段：auctionStartTime（开始时间）、AUCTION_TIME（持续时间）
 *      3. getAuctionPrice() = max(起始价, 起始价 - 衰减量 * 经过时间)
 *      4. 实战场景：NFT 发行、Token IDO（ParaSpace、Azuki 都用过）
 *
 *      Foundry 技巧：vm.deal(addr, amount) 给地址注入 ETH
 */
contract DutchAuctionRawTest is Test {
    DutchAuction public auction;

    /// @dev 部署时自动设置 auctionStartTime = block.timestamp
    function setUp() public {
        auction = new DutchAuction();
    }

    /// @notice 验证初始状态：开始时间和总供应量
    function testInitialState() public view {
        assertEq(auction.auctionStartTime(), block.timestamp);
        assertEq(auction.totalSupply(), 0);
    }

    /// @notice 验证初始拍卖价（拍卖刚开始时的最高价）
    function testGetAuctionPrice() public view {
        uint256 price = auction.getAuctionPrice();
        assertEq(price, 1 ether);
    }

    /// @notice 验证正常铸造：支付 price * quantity
    function testAuctionMint() public {
        uint256 price = auction.getAuctionPrice();
        uint256 quantity = 2;
        uint256 totalCost = price * quantity;

        vm.deal(address(this), totalCost);
        auction.auctionMint{value: totalCost}(quantity);

        assertEq(auction.totalSupply(), quantity);
    }

    /// @notice 验证价格衰减：拍卖结束后价格降到地板价
    /// @dev 教学要点：vm.warp 跳到 AUCTION_TIME 之后，验证衰减逻辑
    function testAuctionMintAfterTime() public {
        vm.warp(block.timestamp + auction.AUCTION_TIME() + 1 minutes);

        uint256 price = auction.getAuctionPrice();
        assertEq(price, 0.1 ether);

        uint256 quantity = 1;
        uint256 totalCost = price * quantity;

        vm.deal(address(this), totalCost);
        auction.auctionMint{value: totalCost}(quantity);

        assertEq(auction.totalSupply(), 1);
    }

    /// @notice 验证未到开始时间时铸造必须 revert
    /// @dev setAuctionStartTime 仅在测试中模拟"项目方设置未来的开始时间"
    function testRevertMintBeforeStart() public {
        DutchAuction newAuction = new DutchAuction();
        newAuction.setAuctionStartTime(uint32(block.timestamp + 100 minutes));

        uint256 price = newAuction.getAuctionPrice();
        vm.deal(address(this), price);
        vm.expectRevert("sale has not started yet");
        newAuction.auctionMint{value: price}(1);
    }
}
