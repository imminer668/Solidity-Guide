// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {MultiCall} from "../../src/raw/MultiCall.sol";

/**
 * @title TestToken
 * @notice 极简 ERC20 mock，仅供 MultiCall 测试使用
 * @dev 教学要点：
 *      - 自包含 mock 避免引入 OZ 依赖，保持 raw 实现的纯净性
 *      - transferFrom 支持无限授权模式（type(uint256).max 时不扣减）
 */
contract TestToken {
    string public name = "Test";
    string public symbol = "TST";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external {
        totalSupply += amount;
        balanceOf[to] += amount;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount);
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(balanceOf[from] >= amount);
        if (allowance[from][msg.sender] != type(uint256).max) {
            require(allowance[from][msg.sender] >= amount);
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

/**
 * @title MultiCallRawTest
 * @notice 原生实现 MultiCall（批量调用）的单元测试
 * @dev 教学重点：
 *      1. MultiCall 把多次调用打包为一次交易，节省 gas
 *      2. 关键结构体 Call { target, allowFailure, callData }
 *      3. allowFailure=true 时子调用失败不影响整体，仅记录 success=false
 *      4. allowFailure=false 时子调用失败会让整个 multicall revert
 *      5. abi.encodeWithSignature 用于构造 callData
 *      6. Multicall3 是行业标准，被 Etherscan 等众多工具采用
 */
contract MultiCallRawTest is Test {
    MultiCall public multicall;
    TestToken public token0;
    TestToken public token1;

    function setUp() public {
        multicall = new MultiCall();
        token0 = new TestToken();
        token1 = new TestToken();
    }

    /// @notice 验证单次调用的 multicall
    function testMulticallSingleCall() public {
        token0.mint(address(this), 1000e18);

        bytes memory mintData = abi.encodeWithSignature("mint(address,uint256)", address(this), 100e18);

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(token0),
            allowFailure: false,
            callData: mintData
        });

        MultiCall.Result[] memory results = multicall.multicall(calls);
        assertTrue(results[0].success);
    }

    /// @notice 验证多个调用按顺序执行，全部成功
    /// @dev 教学要点：先 mint 再 approve 再 transferFrom
    function testMulticallMultipleCalls() public {
        token0.mint(address(this), 1000e18);
        token1.mint(address(this), 1000e18);

        // 授权 multicall 合约可支配 token
        token0.approve(address(multicall), 100e18);
        token1.approve(address(multicall), 200e18);

        bytes memory data0 = abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), address(0x1234), 100e18);
        bytes memory data1 = abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), address(0x5678), 200e18);

        MultiCall.Call[] memory calls = new MultiCall.Call[](2);
        calls[0] = MultiCall.Call({target: address(token0), allowFailure: false, callData: data0});
        calls[1] = MultiCall.Call({target: address(token1), allowFailure: false, callData: data1});

        MultiCall.Result[] memory results = multicall.multicall(calls);
        assertTrue(results[0].success);
        assertTrue(results[1].success);
        assertEq(token0.balanceOf(address(0x1234)), 100e18);
        assertEq(token1.balanceOf(address(0x5678)), 200e18);
    }

    /// @notice 验证 allowFailure=true 时，失败调用不会让整体 revert
    /// @dev 教学要点：子调用失败只标记 success=false，主流程继续
    function testMulticallWithAllowFailure() public {
        bytes memory failingCall = abi.encodeWithSignature("transfer(address,uint256)", address(0x1234), 1);

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(token0),
            allowFailure: true,
            callData: failingCall
        });

        MultiCall.Result[] memory results = multicall.multicall(calls);
        assertTrue(!results[0].success);
    }

    /// @notice 验证 allowFailure=false 时，失败调用会让整体 revert
    function testMulticallRevertOnFailure() public {
        bytes memory failingCall = abi.encodeWithSignature("transfer(address,uint256)", address(0x1234), 1);

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(token0),
            allowFailure: false,
            callData: failingCall
        });

        vm.expectRevert("MultiCall: call failed");
        multicall.multicall(calls);
    }
}
