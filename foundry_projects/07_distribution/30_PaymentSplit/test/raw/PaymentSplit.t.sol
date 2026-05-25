// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {PaymentSplit} from "../../src/raw/PaymentSplit.sol";

/**
 * @title PaymentSplitRawTest
 * @notice 原生实现 PaymentSplit（按份额分配 ETH）的单元测试
 * @dev 教学重点：
 *      1. PaymentSplit 是"按股份分红"模式：按 shares 比例分配合约收到的 ETH
 *      2. 部署时传入 payees + shares 列表，totalShares 决定分配比例
 *      3. releasable() 查询某 payee 当前可领的金额（按已收款项的比例计算）
 *      4. release() 仅当 msg.sender == payee 时才能领取
 */
contract PaymentSplitRawTest is Test {
    PaymentSplit public split;
    address payable public user1 = payable(address(1));
    address payable public user2 = payable(address(2));

    /// @dev user1/user2 份额分别为 1/3，总份额 4
    function setUp() public {
        address[] memory payees = new address[](2);
        payees[0] = user1;
        payees[1] = user2;
        uint256[] memory shares = new uint256[](2);
        shares[0] = 1;
        shares[1] = 3;
        split = new PaymentSplit(payees, shares);
    }

    /// @notice 验证部署后各 payee 的份额及总份额
    function testInitialShares() public {
        assertEq(split.shares(user1), 1);
        assertEq(split.shares(user2), 3);
        assertEq(split.totalShares(), 4);
    }

    /// @notice 验证合约收到 4 ether 后，按 1:3 分配预期
    /// @dev 教学要点：call{value: ...}("") 触发 receive()，无 calldata
    function testReceivePayment() public {
        (bool success,) = address(split).call{value: 4 ether}("");
        require(success);
        assertEq(split.releasable(user1), 1 ether);
        assertEq(split.releasable(user2), 3 ether);
    }

    /// @notice 验证 release 正确转账并更新已领记录
    function testRelease() public {
        (bool success,) = address(split).call{value: 4 ether}("");
        require(success);

        split.release(user1);
        assertEq(user1.balance, 1 ether);
        assertEq(split.released(user1), 1 ether);
    }

    /// @notice 验证两人各自 release 后金额与份额一致
    function testReleaseMultiple() public {
        (bool success,) = address(split).call{value: 4 ether}("");
        require(success);

        split.release(user1);
        split.release(user2);
        assertEq(user1.balance, 1 ether);
        assertEq(user2.balance, 3 ether);
    }
}
