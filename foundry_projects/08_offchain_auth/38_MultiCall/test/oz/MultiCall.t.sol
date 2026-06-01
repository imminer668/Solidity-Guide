// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {MultiCall} from "../../src/raw/MultiCall.sol";
import {MultiCallOZ} from "../../src/oz/MultiCallOZ.sol";

/**
 * @title TestToken
 * @notice 极简 ERC20 mock，供 MultiCallOZ 测试使用
 * @dev 与 raw 测试中的 TestToken 保持完全一致
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
 * @title MultiCallOZTest
 * @notice 基于 OZ 模式实现的 MultiCall 单元测试
 * @dev 与 raw 对比：
 *      - OZ 实现同样提供 multicall + allowFailure 语义
 *      - 核心结构体 Call / Result 保持一致，便于客户端复用
 *      - 业务行为等价
 */
contract MultiCallOZTest is Test {
    MultiCallOZ public multicall;
    TestToken public token;

    /// @dev OZ 版构造无参数
    function setUp() public {
        multicall = new MultiCallOZ();
        token = new TestToken();
    }

    /// @notice 验证单个 transferFrom 的 multicall
    /// @dev 教学要点：先 mint 给 test contract -> 授权给 multicall -> 批量调用
    function testMulticall() public {
        token.mint(address(this), 1000e18);

        token.approve(address(multicall), 100e18);

        bytes memory transferData = abi.encodeWithSignature("transferFrom(address,address,uint256)", address(this), address(0x1234), 100e18);

        MultiCall.Call[] memory calls = new MultiCall.Call[](1);
        calls[0] = MultiCall.Call({
            target: address(token),
            allowFailure: false,
            callData: transferData
        });

        MultiCall.Result[] memory results = multicall.multicall(calls);
        assertTrue(results[0].success);
        assertEq(token.balanceOf(address(0x1234)), 100e18);
    }
}
