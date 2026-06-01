// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ERC721} from "./ERC721.sol";

/**
 * @dev DutchAuction 荷兰拍卖合约 - 原生实现
 */
abstract contract DutchAuctionAbstract is Ownable, ERC721 {
    uint256 public constant COLLECTION_SIZE = 10000;
    uint256 public constant AUCTION_START_PRICE = 1 ether;
    uint256 public constant AUCTION_END_PRICE = 0.1 ether;
    uint256 public constant AUCTION_TIME = 10 minutes;
    uint256 public constant AUCTION_DROP_INTERVAL = 1 minutes;
    uint256 public constant AUCTION_DROP_PER_STEP =
        (AUCTION_START_PRICE - AUCTION_END_PRICE) /
        (AUCTION_TIME / AUCTION_DROP_INTERVAL);

    uint256 public auctionStartTime;
    string private _baseTokenURI;

    constructor(string memory name_, string memory symbol_) ERC721(name_, symbol_) Ownable(msg.sender) {
        auctionStartTime = block.timestamp;
    }

    function setAuctionStartTime(uint32 timestamp) external onlyOwner {
        auctionStartTime = timestamp;
    }

    function getAuctionPrice() public view returns (uint256) {
        if (block.timestamp < auctionStartTime) {
            return AUCTION_START_PRICE;
        } else if (block.timestamp - auctionStartTime >= AUCTION_TIME) {
            return AUCTION_END_PRICE;
        } else {
            uint256 steps = (block.timestamp - auctionStartTime) /
                AUCTION_DROP_INTERVAL;
            return AUCTION_START_PRICE - (steps * AUCTION_DROP_PER_STEP);
        }
    }

    function auctionMint(uint256 quantity) external payable {
        uint256 _saleStartTime = uint256(auctionStartTime);
        require(
            _saleStartTime != 0 && block.timestamp >= _saleStartTime,
            "sale has not started yet"
        );
        require(
            totalSupply() + quantity <= COLLECTION_SIZE,
            "not enough remaining reserved for auction to support desired mint amount"
        );

        uint256 totalCost = getAuctionPrice() * quantity;
        require(msg.value >= totalCost, "Need to send more ETH.");

        for (uint256 i = 0; i < quantity; i++) {
            uint256 mintIndex = totalSupply();
            _mint(msg.sender, mintIndex);
        }

        if (msg.value > totalCost) {
            payable(msg.sender).transfer(msg.value - totalCost);
        }
    }

    function withdrawMoney() external onlyOwner {
        (bool success, ) = msg.sender.call{value: address(this).balance}("");
        require(success, "Transfer failed.");
    }

    function setBaseURI(string memory baseURI) external onlyOwner {
        _baseTokenURI = baseURI;
    }
}

contract DutchAuction is DutchAuctionAbstract {
    constructor() DutchAuctionAbstract("Dutch Auction", "Dutch Auction") {}
}