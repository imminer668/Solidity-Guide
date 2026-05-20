// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC721} from "../../src/raw/ERC721.sol";

/**
 * @title ERC721RawTest
 * @notice 原生实现 ERC721 (NFT) 的单元测试
 * @dev 教学重点：
 *      1. ERC721 是"非同质化代币"标准，每个 tokenId 全局唯一
 *      2. ownerOf(tokenId) 是 ERC721 核心查询，必须能定位到唯一持有者
 *      3. balanceOf(owner) 统计某地址持有的 NFT 数量
 *      4. approve 与 setApprovalForAll 是两套授权粒度：单 token vs 全量
 */
contract ERC721RawTest is Test {
    ERC721 public nft;

    /// @dev 部署时传入 name 和 symbol，与 ERC20 接口不同：ERC721 不需要 decimals
    function setUp() public {
        nft = new ERC721("Test NFT", "TNFT");
    }

    /// @notice 验证 mint 后 ownerOf 与 balanceOf 一致更新
    /// @dev 教学要点：mint 是 ERC721 创造 NFT 的方式（与 ERC20 语义相同）
    function testMint() public {
        nft.mint(address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
        assertEq(nft.balanceOf(address(1)), 1);
    }

    /// @notice 验证 transferFrom 后所有权转移
    function testTransfer() public {
        nft.mint(address(this), 1);
        nft.transferFrom(address(this), address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
        assertEq(nft.balanceOf(address(this)), 0);
        assertEq(nft.balanceOf(address(1)), 1);
    }

    /// @notice 验证单 token 授权：仅 owner 可批准
    /// @dev 教学要点：approve(address, tokenId) 是"单 NFT 授权"，
    ///      spender 仅被允许操作该 tokenId
    function testApprove() public {
        nft.mint(address(this), 1);
        nft.approve(address(2), 1);
        assertEq(nft.getApproved(1), address(2));
    }

    /// @notice 验证全量授权：owner 信任 operator 管理其所有 NFT
    /// @dev 教学要点：setApprovalForAll 是"全量授权"，
    ///      operator 可代表 owner 操作其名下所有 NFT（含未来 mint 的）
    function testSetApprovalForAll() public {
        nft.setApprovalForAll(address(2), true);
        assertTrue(nft.isApprovedForAll(address(this), address(2)));
    }

    /// @notice 验证 safeTransferFrom 的所有权转移
    /// @dev safeTransfer 会校验接收方是否为合约，是则要求实现 IERC721Receiver
    function testSafeTransfer() public {
        nft.mint(address(this), 1);
        nft.safeTransferFrom(address(this), address(1), 1);
        assertEq(nft.ownerOf(1), address(1));
    }

    /// @notice 验证 burn 后该 tokenId 被销毁
    function testBurn() public {
        nft.mint(address(this), 1);
        nft.burn(1);
        assertEq(nft.balanceOf(address(this)), 0);
    }

    /// @notice 验证未设置元数据时 tokenURI 为空字符串
    function testTokenURI() public {
        nft.mint(address(this), 1);
        assertEq(nft.tokenURI(1), "");
    }
}
