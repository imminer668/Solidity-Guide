// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {NFTSwapOZ} from "../../src/oz/NFTSwap.sol";
import {ERC721} from "../../src/raw/ERC721.sol";

/**
 * @title MockNFT
 * @notice 极简 NFT mock，供 NFTSwapOZ 测试使用
 */
contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

/**
 * @title NFTSwapOZTest
 * @notice 基于 OZ 模式实现的 NFTSwap 单元测试
 * @dev 与 raw 对比：
 *      - OZ 实现使用更严格的权限校验（Ownable/ReentrancyGuard）
 *      - 业务接口保持一致：list / purchase / revoke / update
 *      - 业务行为等价
 */
contract NFTSwapOZTest is Test {
    NFTSwapOZ public nftSwap;
    MockNFT public nft;
    address public seller;
    address public buyer;

    /// @dev 同 raw：部署后给 seller 铸造 2 个 NFT
    function setUp() public {
        nftSwap = new NFTSwapOZ();
        nft = new MockNFT();

        seller = address(0x1);
        buyer = address(0x2);

        vm.prank(seller);
        nft.mint(seller, 0);
        vm.prank(seller);
        nft.mint(seller, 1);
    }

    /// @notice 验证挂单
    function testList() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        (address owner, uint256 price) = nftSwap.nftList(address(nft), 0);
        assertEq(owner, seller);
        assertEq(price, 1 ether);
        assertEq(nft.ownerOf(0), address(nftSwap));
    }

    /// @notice 验证取消挂单
    function testRevoke() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        vm.prank(seller);
        nftSwap.revoke(address(nft), 0);

        assertEq(nft.ownerOf(0), seller);
    }

    /// @notice 验证修改价格
    function testUpdate() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        vm.prank(seller);
        nftSwap.update(address(nft), 0, 2 ether);

        (, uint256 price) = nftSwap.nftList(address(nft), 0);
        assertEq(price, 2 ether);
    }

    /// @notice 验证购买
    function testPurchase() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        vm.deal(buyer, 2 ether);
        vm.prank(buyer);
        nftSwap.purchase{value: 1 ether}(address(nft), 0);

        assertEq(nft.ownerOf(0), buyer);
    }
}
