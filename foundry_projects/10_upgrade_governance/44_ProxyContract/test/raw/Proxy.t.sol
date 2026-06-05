// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {Proxy, Logic, Caller} from "../../src/raw/Proxy.sol";

/**
 * @title ProxyRawTest
 * @notice 原生实现 Proxy 模式的单元测试
 * @dev 教学重点：
 *      1. Proxy 模式：合约地址不变，逻辑可替换
 *      2. 关键点：
 *         - Proxy 持有 implementation 地址
 *         - 通过 fallback delegatecall 把调用转发给 implementation
 *         - 状态存储在 Proxy 上，逻辑代码来自 implementation
 *      3. 三种调用场景对比：
 *         a. 直接调 Logic：使用 Logic 自己的状态（x=99 + 1 = 100）
 *         b. 通过 Proxy 调：使用 Proxy 的状态（x=0 + 1 = 1）
 *         c. 通过 Caller 调：Caller 转发到 Proxy
 *      4. delegatecall 与 call 的关键区别：
 *         - call：执行被调方代码，状态写回被调方
 *         - delegatecall：执行被调方代码，但状态写入调用方
 */
contract ProxyRawTest is Test {
    Proxy public proxy;
    Logic public logic;
    Caller public caller;

    /// @dev 部署 logic + proxy（指向 logic）+ caller（调用 proxy）
    function setUp() public {
        logic = new Logic();
        proxy = new Proxy(address(logic));
        caller = new Caller(address(proxy));
    }

    /// @notice 验证初始 implementation 与 logic 状态
    function testInitialState() public view {
        assertEq(proxy.implementation(), address(logic));
        assertEq(logic.x(), 99);
    }

    /// @notice 验证直接调用 Logic 合约：使用 Logic 自身状态
    /// @dev 教学要点：Logic.x 初始为 99，increment 后变 100
    function testDirectLogicCall() public {
        assertEq(logic.increment(), 100);
    }

    /// @notice 验证通过 Proxy 调用 Logic：使用 Proxy 的存储
    /// @dev 教学要点：Proxy 的 x 槽未初始化（值为 0），所以返回 1
    function testProxyCall() public {
        (, bytes memory data) = address(proxy).call(
            abi.encodeWithSignature("increment()")
        );
        uint256 result = abi.decode(data, (uint256));
        assertEq(result, 1);
    }

    /// @notice 验证通过 Caller -> Proxy -> Logic 的链式调用
    /// @dev 教学要点：caller 主动调 proxy，proxy delegatecall logic
    function testCallerThroughProxy() public {
        assertEq(caller.increment(), 1);
    }
}
