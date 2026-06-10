// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console} from "forge-std/Test.sol";
import {SimpleBridgeOZ} from "../../src/oz/SimpleBridge.sol";

/**
 * @title SimpleBridgeOZTest
 * @notice 基于 OZ 模式实现的 SimpleBridgeOZ 单元测试
 * @dev 教学重点：
 *      1. OZ 版基于 OZ 的 ERC20 + Ownable 实现
 *      2. 接口与 raw 版保持一致：mint/burn/lock/unlock
 *      3. 实战推荐：生产环境应使用 LayerZero / Wormhole / Axelar 等专业跨链协议
 *      4. 当前为占位测试，验证合约可正常部署
 *
 *      进阶：完整 OZ 版应测试
 *      - transferOwnership 后的权限变更
 *      - Pausable 紧急暂停
 *      - 重入保护（ReentrancyGuard）
 */
contract SimpleBridgeOZTest is Test {
    SimpleBridgeOZ public bridge;

    /// @dev OZ 版部署无参数
    function setUp() public {
        bridge = new SimpleBridgeOZ();
    }

    /// @notice 占位测试：验证合约部署成功
    function testPlaceholder() public view {
        // OZ 实现的详细测试在 src/oz/SimpleBridge.sol 中
        // 此处占位以保持测试套件可编译
    }
}
