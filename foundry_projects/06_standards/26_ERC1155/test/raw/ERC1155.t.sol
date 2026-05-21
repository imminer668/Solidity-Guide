// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ERC1155} from "../../src/raw/ERC1155.sol";

/**
 * @title ERC1155RawTest
 * @notice 原生实现 ERC1155 多代币标准的单元测试
 * @dev 教学重点：
 *      1. ERC1155 是"多代币"标准：单一合约管理多种 tokenId
 *      2. balanceOf(account, id) 是二维查询：账户 x tokenId
 *      3. mint/burn 是单 token 操作；mintBatch/burnBatch 是批量操作
 *      4. balanceOfBatch 一次返回多账户多 tokenId 的余额，节省 gas
 *      5. setApprovalForAll 是 ERC1155 唯一的授权方式（没有单 token approve）
 */
contract ERC1155RawTest is Test {
    ERC1155 public token;

    /// @dev 部署时传入 uri 模板（未设置时为 ""）
    function setUp() public {
        token = new ERC1155("Multi Token", "MTK");
    }

    /// @notice 验证单 tokenId 铸造后余额正确
    function testMint() public {
        token.mint(address(2), 1, 100);
        assertEq(token.balanceOf(address(2), 1), 100);
    }

    /// @notice 验证批量铸造：一次铸造多个 tokenId + 对应数量
    /// @dev 教学要点：mintBatch 一次操作多个 id+amount，gas 效率高于多次 mint
    function testMintBatch() public {
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100;
        amounts[1] = 200;
        token.mintBatch(address(2), ids, amounts);
        assertEq(token.balanceOf(address(2), 1), 100);
        assertEq(token.balanceOf(address(2), 2), 200);
    }

    /// @notice 验证销毁后余额减少
    function testBurn() public {
        token.mint(address(2), 1, 100);
        token.burn(address(2), 1, 50);
        assertEq(token.balanceOf(address(2), 1), 50);
    }

    /// @notice 验证 uri 在未设置时返回空字符串
    function testUri() public {
        token.mint(address(2), 1, 100);
        assertEq(token.uri(1), "");
    }

    /// @notice 验证 balanceOfBatch 批量查询
    /// @dev 教学要点：balanceOfBatch 一次返回 (account, id) 矩阵的所有余额
    function testBalanceOfBatch() public {
        token.mint(address(2), 1, 100);
        token.mint(address(2), 2, 200);
        address[] memory accounts = new address[](2);
        accounts[0] = address(2);
        accounts[1] = address(2);
        uint256[] memory ids = new uint256[](2);
        ids[0] = 1;
        ids[1] = 2;
        uint256[] memory balances = token.balanceOfBatch(accounts, ids);
        assertEq(balances[0], 100);
        assertEq(balances[1], 200);
    }

    /// @notice 验证全量授权：与 ERC721 相同，仅 operator 级
    function testSetApprovalForAll() public {
        token.setApprovalForAll(address(2), true);
        assertTrue(token.isApprovedForAll(address(this), address(2)));
    }
}
