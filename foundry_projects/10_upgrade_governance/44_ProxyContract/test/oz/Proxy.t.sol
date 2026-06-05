// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {ProxyOZ} from "../../src/oz/Proxy.sol";
import {Logic} from "../../src/raw/Proxy.sol";

/**
 * @title ProxyOZTest
 * @notice 基于 OZ 模式实现的 Proxy 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版继承 OZ 的 ERC1967Proxy，遵循 EIP-1967 存储槽规范
 *      - 行为等价：都通过 delegatecall 转发调用
 *      - 业务行为一致
 */
contract ProxyOZTest is Test {
    ProxyOZ public proxy;
    Logic public logic;

    /// @dev 部署 Logic + ProxyOZ（指向 Logic）
    function setUp() public {
        logic = new Logic();
        proxy = new ProxyOZ(address(logic));
    }

    /// @notice 验证 implementation 绑定
    function testInitialState() public view {
        assertEq(proxy.implementation(), address(logic));
    }

    /// @notice 验证 delegatecall 行为
    /// @dev 教学要点：调用结果与 raw 版一致（使用 Proxy 自己的存储）
    function testProxyCall() public {
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSignature("increment()")
        );
        uint256 result = abi.decode(data, (uint256));
        assertEq(result, 1);
    }
}
