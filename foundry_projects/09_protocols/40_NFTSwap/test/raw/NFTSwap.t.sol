// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {NFTSwap} from "../../src/raw/NFTSwap.sol";
import {ERC721} from "../../src/raw/ERC721.sol";

/**
 * @title MockNFT
 * @notice 极简 NFT mock，供 NFTSwap 测试使用
 * @dev 教学要点：测试中用 _mint 暴露给 mock 即可，无需完整 ERC721 接收方校验
 */
contract MockNFT is ERC721 {
    constructor() ERC721("MockNFT", "MNFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}

/**
 * @title NFTSwapRawTest
 * @notice 原生实现 NFTSwap（P2P NFT 交易所）的单元测试
 * @dev 教学重点：
 *      1. NFTSwap 是 P2P NFT 撮合：卖家挂单、买家购买
 *      2. 关键流程：
 *         - list: 卖家授权 NFT + 转移 NFT 到 swap + 设置价格
 *         - purchase: 买家支付 ETH -> NFT 转给买家
 *         - revoke: 卖家取消挂单
 *         - update: 卖家修改价格
 *      3. purchase 多付的 ETH 必须自动退款（防溢出）
 *      4. Found cheatcode: vm.deal(addr, amount) 注入 ETH
 */
contract NFTSwapRawTest is Test {
    NFTSwap public nftSwap;
    MockNFT public nft;
    address public seller;
    address public buyer;

    /// @dev 部署 NFTSwap + MockNFT，给 seller 铸造 2 个 NFT
    function setUp() public {
        nftSwap = new NFTSwap();
        nft = new MockNFT();

        seller = address(0x1);
        buyer = address(0x2);

        vm.prank(seller);
        nft.mint(seller, 0);
        vm.prank(seller);
        nft.mint(seller, 1);
    }

    /// @notice 验证挂单：NFT 转移到 swap，记录价格
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

    /// @notice 验证取消挂单：NFT 退还给 seller
    function testRevoke() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        vm.prank(seller);
        nftSwap.revoke(address(nft), 0);

        assertEq(nft.ownerOf(0), seller);
    }

    /// @notice 验证修改挂单价格
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

    /// @notice 验证购买：买家支付正确金额后获得 NFT
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

    /// @notice 验证多付自动退款
    /// @dev 教学要点：买家发送 2 ether，但价格 1 ether，剩余 1 ether 必须退回
    function testPurchaseWithExtraRefund() public {
        vm.prank(seller);
        nft.approve(address(nftSwap), 0);

        vm.prank(seller);
        nftSwap.list(address(nft), 0, 1 ether);

        vm.deal(buyer, 5 ether);
        uint256 buyerBalanceBefore = buyer.balance;
        vm.prank(buyer);
        nftSwap.purchase{value: 2 ether}(address(nft), 0);

        assertEq(nft.ownerOf(0), buyer);
        assertEq(buyer.balance, buyerBalanceBefore - 1 ether);
    }
}
