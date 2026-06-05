// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {Test, console} from "forge-std/Test.sol";
import {SimpleUpgradeOZ} from "../../src/oz/SimpleUpgrade.sol";
import {Logic1} from "../../src/raw/Logic1.sol";

/**
 * @title SimpleUpgradeOZTest
 * @notice 基于 OZ TransparentUpgradeableProxy 的 SimpleUpgradeOZ 单元测试
 * @dev 教学重点：
 *      1. OZ 版继承 OZ 的 TransparentUpgradeableProxy
 *      2. 遵循 EIP-1967 规范：implementation 存在 keccak256("eip1967.proxy.implementation")-1 槽
 *      3. 教学要点：vm.load(addr, slot) 可读取任意 storage slot
 *      4. 与 raw 版的区别：
 *         - raw：自定义 admin + 自定义 upgrade 流程
 *         - OZ：标准 admin（proxy admin） + upgradeToAndCall
 *
 *      本测试聚焦于"部署 + storage slot 校验"，完整升级流程见 test/raw/
 */
contract SimpleUpgradeOZTest is Test {
    SimpleUpgradeOZ public proxy;
    Logic1 public logic1;

    /// @dev 部署 Logic1 + SimpleUpgradeOZ（指向 Logic1，data="" 不调用初始化）
    function setUp() public {
        logic1 = new Logic1();
        proxy = new SimpleUpgradeOZ(address(logic1), "");
    }

    /// @notice 验证 OZ proxy 部署成功
    /// @dev 教学要点：assertTrue 校验布尔条件
    function testOZProxyDeployment() public view {
        assertTrue(address(proxy) != address(0), "OZ proxy not deployed");
    }

    /// @notice 验证 ERC-1967 implementation slot 正确存储
    /// @dev 教学要点：
    ///      - EIP-1967 槽位 = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1)
    ///      - 减 1 是为了避开预编译/系统合约可能使用的 0x0 槽
    ///      - vm.load(address, slot) 直接读取 EVM 存储槽
    function testOZImplementationSlot() public view {
        bytes32 implSlot = bytes32(uint256(keccak256("eip1967.proxy.implementation")) - 1);
        bytes32 storedImpl = vm.load(address(proxy), implSlot);
        assertEq(storedImpl, bytes32(uint256(uint160(address(logic1)))), "Implementation mismatch");
    }
}
