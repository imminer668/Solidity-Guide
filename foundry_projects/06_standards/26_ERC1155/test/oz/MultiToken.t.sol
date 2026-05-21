// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {MultiToken} from "../../src/oz/MultiToken.sol";

/**
 * @title MultiTokenTest
 * @notice 基于 OpenZeppelin ERC1155 实现的单元测试
 * @dev 与 raw 对比：OZ 版继承 OZ 的 ERC1155，自带：
 *      - _mint/_mintBatch 内部钩子
 *      - _doSafeTransferAcceptanceCheck 安全接收校验
 *      - 完整事件（TransferSingle/TransferBatch/ApprovalForAll/URI）
 *
 *      构造时传入 baseURI（"ipfs://example/"），所有 tokenId 共享此 URI
 */
contract MultiTokenTest is Test {
    MultiToken public token;

    /// @dev 部署时传入 baseURI，所有 tokenId 通过 baseURI+id 拼成完整 URI
    function setUp() public {
        token = new MultiToken("ipfs://example/");
    }

    /// @notice 验证单 tokenId 铸造
    function testMint() public {
        token.mint(address(2), 1, 100);
        assertEq(token.balanceOf(address(2), 1), 100);
    }

    /// @notice 验证批量铸造
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

    /// @notice 验证 uri 返回 baseURI（OZ 版默认行为）
    /// @dev 与 raw 对比：raw 默认返回 ""，OZ 默认会返回构造时设置的 baseURI
    function testUri() public {
        token.mint(address(2), 1, 100);
        string memory uri = token.uri(1);
        assertGt(bytes(uri).length, 0);
    }

    /// @notice 验证全量授权机制
    function testSetApprovalForAll() public {
        token.setApprovalForAll(address(2), true);
        assertTrue(token.isApprovedForAll(address(this), address(2)));
    }
}
