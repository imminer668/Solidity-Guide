// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {NFTToken} from "../../src/oz/NFTToken.sol";

/**
 * @title NFTTokenTest
 * @notice 基于 OpenZeppelin ERC721 实现的单元测试
 * @dev 与 raw 对比：OZ 版继承 OZ 的 ERC721，并附带：
 *      - 完整 EIP-721 元数据（name/symbol/tokenURI）
 *      - IERC721Receiver 钩子（safeMint 自动校验）
 *      - 全套事件（Transfer/Approval/ApprovalForAll）
 *
 *      构造时传入 maxSupply 是 OZ 教程中常见的"限量"扩展
 */
contract NFTTokenTest is Test {
    NFTToken public nft;

    /// @dev 部署时显式传入 maxSupply=10000，演示"限量铸造"模式
    function setUp() public {
        nft = new NFTToken("Test NFT", "TNFT", 10000);
    }

    /// @notice 验证 mint 后 ownerOf 与 balanceOf 正确同步
    function testMint() public {
        nft.mint(address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
        assertEq(nft.balanceOf(address(1)), 1);
    }

    /// @notice 验证 transferFrom 后所有权正确转移
    function testTransfer() public {
        nft.mint(address(this), 1);
        nft.transferFrom(address(this), address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
        assertEq(nft.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(1)), 1);
    }

    /// @notice 验证单 token 授权生效
    function testApprove() public {
        nft.mint(address(this), 1);
        nft.approve(address(2), 1);
        assertEq(nft.getApproved(1), address(2));
    }

    /// @notice 验证 setApprovalForAll 信任授权机制
    function testSetApprovalForAll() public {
        nft.setApprovalForAll(address(2), true);
        assertTrue(nft.isApprovedForAll(address(this), address(2)));
    }

    /// @notice 验证 safeTransferFrom 正确转移所有权
    function testSafeTransfer() public {
        nft.mint(address(this), 1);
        nft.safeTransferFrom(address(this), address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
    }

    /// @notice 验证 tokenURI 返回非空（OZ 版基于 baseURI 拼接）
    /// @dev 与 raw 对比：raw 默认返回 ""，OZ 默认会拼接 baseURI+tokenId
    function testTokenURI() public {
        nft.mint(address(this), 1);
        string memory uri = nft.tokenURI(1);
        assertGt(bytes(uri).length, 0);
    }
}
