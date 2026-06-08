// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {TransparentProxyOZ} from "../../src/oz/TransparentProxy.sol";
import {Logic1} from "../../src/raw/Logic1.sol";

/**
 * @title TransparentProxyOZTest
 * @notice 基于 OZ 模式实现的 TransparentProxyOZ 单元测试
 * @dev 教学重点：
 *      1. OZ 版继承 OZ 的 TransparentUpgradeableProxy + ProxyAdmin
 *      2. 遵循 EIP-1967 存储槽规范
 *      3. 透明代理特性：admin 调 Logic 函数被 reject
 *      4. 与 raw 版的区别：
 *         - raw：自定义实现 + require(msg.sender == admin) 模式
 *         - OZ：标准实现 + 更严格的行为隔离
 *
 *      本测试聚焦于"部署 + storage slot 校验"
 */
contract TransparentProxyOZTest is Test {
    TransparentProxyOZ public proxy;
    Logic1 public logic1;

    /// @dev 部署 Logic1 + TransparentProxyOZ（data="" 不调用初始化）
    function setUp() public {
        logic1 = new Logic1();
        proxy = new TransparentProxyOZ(address(logic1), "");
    }

    /// @notice 验证 OZ proxy 部署成功
    function testOZProxyDeployment() public view {
        assertTrue(address(proxy) != address(0), "OZ proxy not deployed");
    }

    /// @notice 验证 ERC-1967 implementation slot
    /// @dev 教学要点：vm.load 读取原始 EVM storage slot
    function testOZImplementationSlot() public view {
        bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 storedImpl = vm.load(address(proxy), implSlot);
        assertEq(storedImpl, bytes32(uint256(uint160(address(logic1)))), "Implementation mismatch");
    }
}
