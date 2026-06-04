// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SimpleFlashloan, MockERC20} from "../../src/raw/Flashloan.sol";

/**
 * @title FlashloanReceiver
 * @notice 闪电贷接收者合约，演示完整流程
 * @dev 教学重点：
 *      1. 闪电贷核心思想：借-用-还，全部在同一笔交易内完成
 *      2. 接收方实现 onFlashloan 回调，被借贷合约主动调用
 *      3. 回调中必须还款（含手续费），否则整个交易 revert
 *      4. 手续费算法：fee = amount * 3 / 1000 + 1（Aave 经典 0.3%）
 *      5. 应用：套利、抵押品互换、杠杆清算
 */
contract FlashloanReceiver {
    SimpleFlashloan public flashloan;
    address public token;

    constructor(address _flashloan, address _token) {
        flashloan = SimpleFlashloan(_flashloan);
        token = _token;
    }

    /// @notice 接收方回调：归还本金 + 0.3% 手续费
    /// @dev 教学要点：
    ///      - 校验 msg.sender == flashloan 防止伪调用
    ///      - 必须在回调内还款
    function onFlashloan(address, uint256 amount, bytes calldata) external returns (bool) {
        require(msg.sender == address(flashloan), "Only flashloan");

        uint256 fee = (amount * 3) / 1000 + 1;
        uint256 repayAmount = amount + fee;

        // 从本合约余额中还款（需先转入 receiver）
        MockERC20(token).transfer(address(flashloan), repayAmount);

        return true;
    }

    /// @notice 外部请求闪电贷
    function requestFlashloan(uint256 amount) external {
        flashloan.flashloan(token, amount, bytes(""));
    }
}

/**
 * @title FlashloanRawTest
 * @notice 原生实现 SimpleFlashloan 的单元测试
 * @dev 教学重点：
 *      1. 闪电贷合约本身不存钱也可工作（仅作"中转"）
 *      2. 测试中先给 receiver 转账，让其有足够余额还款
 *      3. 校验 flashloan 合约的余额在借-还后增加（手续费）
 *      4. Foundry cheatcode: assertGt(a, b) 校验 a > b
 */
contract FlashloanRawTest is Test {
    SimpleFlashloan public flashloan;
    MockERC20 public token;
    FlashloanReceiver public receiver;

    /// @dev 部署 flashloan + mock token，给 flashloan 注入 1000e18 流动性
    function setUp() public {
        flashloan = new SimpleFlashloan();
        token = new MockERC20("Mock Token", "MOCK");
        receiver = new FlashloanReceiver(address(flashloan), address(token));

        token.mint(address(flashloan), 1000e18);
    }

    /// @notice 验证初始资金分布
    function testInitialState() public view {
        assertEq(token.balanceOf(address(flashloan)), 1000e18);
        assertEq(token.balanceOf(address(receiver)), 0);
    }

    /// @notice 验证完整借-还流程
    /// @dev 教学要点：fee = 100e18 * 3/1000 + 1 = 0.3e18 + 1
    function testFlashloanWithRepayment() public {
        uint256 borrowAmount = 100e18;
        uint256 initialFlashloanBalance = token.balanceOf(address(flashloan));

        // 给 receiver 转入足额还款
        uint256 fee = (borrowAmount * 3) / 1000 + 1;
        token.mint(address(receiver), fee + 10e18);

        // 模拟 receiver 调用请求
        vm.prank(address(receiver));
        receiver.requestFlashloan(borrowAmount);

        // flashloan 合约余额应当增加（手续费）
        assertGt(token.balanceOf(address(flashloan)), initialFlashloanBalance);
    }

    /// @notice 验证超额借款必须 revert
    function testRevertInsufficientBalance() public {
        vm.expectRevert("Insufficient balance");
        flashloan.flashloan(address(token), 2000e18, bytes(""));
    }

    /// @notice 验证借 0 必须 revert
    function testRevertZeroAmount() public {
        vm.expectRevert("Amount must be positive");
        flashloan.flashloan(address(token), 0, bytes(""));
    }
}
