// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Test, console} from "forge-std/Test.sol";
import {SimpleRandomOZ} from "../../src/oz/SimpleRandom.sol";
import {VRFCoordinatorV2Mock} from "./VRFCoordinatorV2Mock.sol";

/**
 * @title SimpleRandomOZTest
 * @notice 基于 Chainlink VRF v2 的 SimpleRandomOZ 单元测试
 * @dev 教学重点：
 *      1. Chainlink VRF = 可验证随机函数：链下生成 + 链上验证
 *      2. 工作流程：
 *         a. 用户调 requestRandom() -> 合约调 VRFCoordinator.requestRandomWords()
 *         b. Chainlink 预言机在链下生成可验证随机数
 *         c. 预言机回调 fulfillRandomWords() 提交结果
 *         d. 用户通过 getRandomResult(requestId) 读取
 *      3. 关键优势：
 *         - 预言机无法预知 requestId 之后的区块（防止矿工操纵）
 *         - 链下生成 + 链上验证
 *         - 业界标准的可验证随机性方案
 *      4. 本测试用 VRFCoordinatorV2Mock 模拟预言机：
 *         - setSeed(requestId, value): 预设随机数
 *         - fulfillRandomWords(requestId, consumer): 手动触发回调
 *      5. 与 raw 版对比：
 *         - raw：链上伪随机（不安全，矿工可操纵）
 *         - OZ：链下可验证随机（生产可用）
 */
contract SimpleRandomOZTest is Test {
    SimpleRandomOZ public random;
    VRFCoordinatorV2Mock public coordinator;

    /// @dev Chainlink VRF 通用配置（生产环境从 Chainlink 文档获取）
    bytes32 constant KEY_HASH = bytes32(uint256(0x1));
    uint64 constant SUB_ID = 1;
    uint32 constant CALLBACK_GAS = 100000;
    uint16 constant CONFIRMATIONS = 3;

    /// @dev 测试用地址
    address public alice = address(0xA11CE);
    address public bob = address(0xB0B);

    /// @dev 部署 mock coordinator + 消费合约
    function setUp() public {
        coordinator = new VRFCoordinatorV2Mock();
        random = new SimpleRandomOZ(
            address(coordinator),
            KEY_HASH,
            SUB_ID,
            CALLBACK_GAS,
            CONFIRMATIONS
        );
    }

    /// @notice 验证部署参数正确
    function testDeployment() public view {
        assertEq(random.vrfCoordinator(), address(coordinator), "Coordinator mismatch");
        assertEq(random.owner(), address(this), "Owner mismatch");
        assertEq(random.keyHash(), KEY_HASH, "KeyHash mismatch");
    }

    /// @notice 验证请求 VRF 后 requestId 分配正确
    function testRequestRandom() public {
        vm.prank(alice);
        uint256 requestId = random.requestRandom();
        assertEq(requestId, 1, "First request id should be 1");
        assertEq(random.requestToRequester(requestId), alice, "Requester mismatch");
    }

    /// @notice 验证 mock 触发 fulfill 后随机数被记录
    function testFulfillRandomWords() public {
        vm.prank(alice);
        uint256 requestId = random.requestRandom();

        uint256 expectedSeed = 12345;
        coordinator.setSeed(requestId, expectedSeed);

        coordinator.fulfillRandomWords(requestId, address(random));

        assertEq(random.requestToRandom(requestId), expectedSeed, "Random result mismatch");
    }

    /// @notice 验证 getRandomResult 正确返回结果
    function testGetRandomResult() public {
        vm.prank(alice);
        uint256 requestId = random.requestRandom();
        uint256 expectedSeed = 99999;
        coordinator.setSeed(requestId, expectedSeed);
        coordinator.fulfillRandomWords(requestId, address(random));

        uint256 result = random.getRandomResult(requestId);
        assertEq(result, expectedSeed, "Result mismatch");
    }

    /// @notice 验证查询未知 requestId 必须 revert
    function testGetRandomResult_NotFoundReverts() public {
        vm.expectRevert(abi.encodeWithSignature("RequestNotFound(uint256)", 999));
        random.getRandomResult(999);
    }

    /// @notice 验证未完成的请求必须 revert
    function testGetRandomResult_NotFulfilledReverts() public {
        vm.prank(alice);
        uint256 requestId = random.requestRandom();
        vm.expectRevert(abi.encodeWithSignature("RequestNotFulfilled(uint256)", requestId));
        random.getRandomResult(requestId);
    }

    /// @notice 验证仅 coordinator 可触发 fulfill（防伪调用）
    /// @dev 教学要点：bob 尝试直接调 rawFulfillRandomWords 应当被 reject
    function testOnlyCoordinatorCanFulfill() public {
        vm.prank(alice);
        uint256 requestId = random.requestRandom();
        uint256[] memory words = new uint256[](1);
        words[0] = 1234;
        vm.expectRevert(abi.encodeWithSignature("OnlyCoordinatorCanFulfill(address,address)", bob, address(coordinator)));
        vm.prank(bob);
        random.rawFulfillRandomWords(requestId, words);
    }

    /// @notice 验证同一用户的多次请求被独立记录
    function testMultipleRequestsFromSameUser() public {
        vm.startPrank(alice);
        uint256 r1 = random.requestRandom();
        uint256 r2 = random.requestRandom();
        uint256 r3 = random.requestRandom();
        vm.stopPrank();

        uint256[] memory requests = random.getUserRequests(alice);
        assertEq(requests.length, 3, "Should have 3 requests");
        assertEq(requests[0], r1, "First request id mismatch");
        assertEq(requests[1], r2, "Second request id mismatch");
        assertEq(requests[2], r3, "Third request id mismatch");
    }

    /// @notice 验证不同用户独立请求、互不干扰
    function testMultipleUsersIndependent() public {
        vm.prank(alice);
        uint256 aliceReq = random.requestRandom();
        vm.prank(bob);
        uint256 bobReq = random.requestRandom();

        coordinator.setSeed(aliceReq, 100);
        coordinator.setSeed(bobReq, 200);

        coordinator.fulfillRandomWords(aliceReq, address(random));
        coordinator.fulfillRandomWords(bobReq, address(random));

        assertEq(random.getRandomResult(aliceReq), 100, "Alice result wrong");
        assertEq(random.getRandomResult(bobReq), 200, "Bob result wrong");
    }

    /// @notice 验证仅 owner 可设置请求配置
    function testSetRequestConfigOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        random.setRequestConfig(2, 200000, 5);
    }

    /// @notice 验证 setRequestConfig 正确更新
    function testSetRequestConfig() public {
        random.setRequestConfig(99, 200000, 5);
        (uint64 subId, uint32 gasLimit, uint16 confs) = random.requestConfig();
        assertEq(subId, 99, "SubId mismatch");
        assertEq(gasLimit, 200000, "GasLimit mismatch");
        assertEq(confs, 5, "Confirmations mismatch");
    }

    /// @notice 验证 setKeyHash 正确更新
    function testSetKeyHash() public {
        bytes32 newKey = bytes32(uint256(0xABCDEF));
        random.setKeyHash(newKey);
        assertEq(random.keyHash(), newKey, "KeyHash not updated");
    }

    /// @notice 验证仅 owner 可设置 keyHash
    function testSetKeyHashOnlyOwner() public {
        vm.prank(alice);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", alice));
        random.setKeyHash(bytes32(uint256(0x123)));
    }

    /// @notice 验证未知 requestId 被 fulfill 时必须 revert
    function testFulfillInvalidRequestReverts() public {
        uint256[] memory words = new uint256[](1);
        words[0] = 1;
        vm.expectRevert(bytes("Invalid request"));
        coordinator.fulfillRandomWords(999, address(random));
    }
}
