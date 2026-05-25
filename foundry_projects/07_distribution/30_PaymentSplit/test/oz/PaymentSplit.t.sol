// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {PaymentSplitOZ} from "../../src/oz/PaymentSplit.sol";

/**
 * @title PaymentSplitOZTest
 * @notice 基于 OZ 模式实现的 PaymentSplit 单元测试
 * @dev 与 raw 对比：
 *      - 接口一致（payees/shares/totalShares/releasable/release）
 *      - OZ 实现通常更省 gas，并附 PaymentReceived / PaymentReleased 事件
 *      - 业务行为与 raw 完全等价
 */
contract PaymentSplitOZTest is Test {
    PaymentSplitOZ public split;
    address payable public user1 = payable(address(1));
    address payable public user2 = payable(address(2));

    /// @dev 1:3 份额
    function setUp() public {
        address[] memory payees = new address[](2);
        payees[0] = user1;
        payees[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 3;
        split = new PaymentSplitOZ(payees, shares);
    }

    /// @notice 验证初始份额与总份额
    function testInitialShares() public {
        assertEq(split.shares(user1), 1);
        assertEq(split.shares(user2), 3);
        assertEq(split.totalShares(), 4);
    }

    /// @notice 验证合约收到 ETH 后，releasable 正确按比例计算
    function testReceivePayment() public {
        (bool success,) = address(split).call{value: 4 ether}("");
        require(success);
        assertEq(split.releasable(user1), 1 ether);
        assertEq(split.releasable(user2), 3 ether);
    }

    /// @notice 验证 release 后余额到账
    function testRelease() public {
        (bool success,) = address(split).call{value: 4 ether}("");
        require(success);

        split.release(user1);
        assertEq(user1.balance, 1 ether);
    }
}
