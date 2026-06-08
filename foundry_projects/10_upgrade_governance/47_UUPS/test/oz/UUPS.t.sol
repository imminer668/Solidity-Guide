// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {UUPSLogicV1OZ, UUPSLogicV2OZ} from "../../src/oz/UUPS.sol";

/**
 * @title UUPSOZTest
 * @notice 基于 OZ 模式实现的 UUPS 单元测试
 * @dev 与 raw 对比：
 *      - OZ 版继承 OZ 的 UUPSUpgradeable、Initializable、Ownable
 *      - 升级入口：upgradeToAndCall，符合 OZ 标准
 *      - 部署：ERC1967Proxy + 初始化数据
 *      - 业务行为等价
 *
 * 教学重点：
 *      1. UUPS + ERC1967Proxy 是 EIP-1822 + EIP-1967 的标准组合
 *      2. 升级逻辑放在 implementation 中
 *      3. 部署时通过 initData 调用 initialize（一次性）
 */
contract UUPSOZTest is Test {
    UUPSLogicV1OZ public implementationV1;
    UUPSLogicV2OZ public implementationV2;
    ERC1967Proxy public proxy;
    address public admin;

    /// @dev 部署两个 implementation + ERC1967Proxy（initData 调 initialize）
    function setUp() public {
        admin = address(this);
        implementationV1 = new UUPSLogicV1OZ();
        implementationV2 = new UUPSLogicV2OZ();
        bytes memory initData = abi.encodeCall(UUPSLogicV1OZ.initialize, (admin));
        proxy = new ERC1967Proxy(address(implementationV1), initData);
    }

    /// @notice 验证 OZ UUPS proxy 部署成功
    function testOZUUPSDeployment() public view {
        assertTrue(address(proxy) != address(0), "OZ UUPS proxy not deployed");
    }

    /// @notice 验证 initialize 已被调用，admin 设置正确
    /// @dev 教学要点：
    ///      - 将 proxy 地址强转为 implementation 类型来调用其方法
    ///      - OZ 的 Initializable 防止重复初始化
    function testOZUUPSInitialize() public {
        UUPSLogicV1OZ instance = UUPSLogicV1OZ(address(proxy));
        assertEq(instance.admin(), admin, "Admin mismatch");
    }

    /// @notice 验证升级到 V2 后，words 状态保留
    /// @dev 教学要点：
    ///      - upgradeToAndCall 是 OZ 的标准升级函数
    ///      - 升级后 V2 看到 V1 写入的 words = "old"
    function testOZUUPSUpgrade() public {
        UUPSLogicV1OZ instance = UUPSLogicV1OZ(address(proxy));
        instance.upgradeTo(address(implementationV2));

        UUPSLogicV2OZ instanceV2 = UUPSLogicV2OZ(address(proxy));
        assertEq(instanceV2.getWords(), "old", "Words preserved through upgrade");
    }
}
