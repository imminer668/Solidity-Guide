// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import "forge-std/Test.sol";
import "src/15_CallDemo.sol";

contract CallDemoTest is Test {
    LogicContract public logic;
    ProxyContract public proxy;

    function setUp() public {
        logic = new LogicContract();
        proxy = new ProxyContract();
    }

    // ===== call 测试 =====

    function testCallSetValue() public {
        logic.setValue(42);
        assertEq(logic.value(), 42);
    }

    function testCallGetValue() public {
        logic.setValue(99);
        assertEq(logic.getValue(), 99);
    }

    // ===== delegatecall 测试 =====

    // 核心测试：delegatecall 修改的是 proxy 的 storage，不是 logic 的
    function testDelegatecallModifiesProxyStorage() public {
        // 用 proxy 的 execute 函数，delegatecall 调用 logic 的 setValue
        proxy.execute(address(logic), 100);

        // logic 自己的 value 不受影响
        assertEq(logic.value(), 0); // 从未设置过，保持 0

        // proxy 的 value 被修改了（这就是 delegatecall 的效果）
        assertEq(proxy.value(), 100);
    }

    // delegatecall 后 proxy 能读到自己被修改的值
    function testDelegatecallReadAfterModify() public {
        assertEq(proxy.value(), 0); // 初始值

        proxy.execute(address(logic), 200);

        assertEq(proxy.readValue(), 200); // 通过 proxy 的 readValue 读取
        assertEq(proxy.value(), 200);     // 直接读取 proxy.value
    }

    // 验证：直接调用 setValue 和 delegatecall 调用 setValue 结果互不影响
    function testBothContractsSameLayout() public {
        // 直接用 call 设置 logic 的 value（这是普通函数调用，不是 delegatecall）
        logic.setValue(50);
        assertEq(logic.value(), 50);
        assertEq(proxy.value(), 0); // proxy 不受影响

        // 通过 delegatecall 设置 proxy 的 value
        proxy.execute(address(logic), 50);
        assertEq(proxy.value(), 50); // proxy 被修改
        assertEq(logic.value(), 50); // logic 不受影响（仍然是上一步直接调用设置的 50）
    }

    // 对比：call 不修改 caller 的 storage
    function testCallDoesNotModifyCaller() public {
        // 用 call 调用 logic 的 getValue，call 本身不会修改任何 storage
        // 验证 logic.setValue 直接调用不受影响
        logic.setValue(77);
        assertEq(logic.value(), 77);
        assertEq(proxy.value(), 0); // proxy 不受影响
    }
}
