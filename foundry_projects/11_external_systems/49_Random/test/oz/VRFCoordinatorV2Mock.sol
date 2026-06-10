// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {IVRFCoordinatorV2} from "../../src/oz/VRFConsumerBaseV2.sol";

/**
 * @title VRFCoordinatorV2Mock
 * @notice 本地测试用 Chainlink VRF 协调器 mock
 * @dev 教学重点：
 *      1. 真实 Chainlink VRFCoordinator 由 Chainlink 部署在主网
 *         - Ethereum: 0x271682DEB8C4E7841D88A6530366E1A1B3B6E0B8
 *         - 实际调用涉及 LINK 代币 + 订阅管理
 *      2. 本 mock 模拟其核心行为：
 *         - 分配递增的 requestId
 *         - 记录每个请求的元数据
 *         - 提供 setSeed 让测试预设随机数
 *         - 主动调用消费者的 rawFulfillRandomWords
 *      3. 关键设计：测试中可确定性控制随机数（避免 flaky test）
 *      4. 真实环境应替换为 Chainlink 部署的协调器
 */
contract VRFCoordinatorV2Mock is IVRFCoordinatorV2 {
    /// @dev 自增 requestId 计数器
    uint256 private _nextRequestId = 1;
    /// @dev mock 假定的 LINK 手续费（测试中不实际收取）
    uint256 public constant MOCK_FEE = 0.25 ether;

    /// @dev 请求元数据：subId/callbackGas/keyHash
    struct RequestMeta {
        uint64 subId;
        uint32 callbackGasLimit;
        bytes32 keyHash;
    }

    /// @dev requestId -> 请求元数据
    mapping(uint256 => RequestMeta) public requests;
    /// @dev requestId -> 预设的随机数（测试用）
    mapping(uint256 => uint256) public preSeed;

    /// @notice 模拟 requestRandomWords：分配 requestId 并记录元数据
    /// @dev 教学要点：
    ///      1. 真实环境会校验订阅余额、扣 LINK 费等
    ///      2. mock 中直接分配递增 requestId
    ///      3. 默认种子用 prevrandao + requestId 派生（生产可改为可预测值）
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external override returns (uint256 requestId) {
        requestId = _nextRequestId++;
        requests[requestId] = RequestMeta({
            subId: subId,
            callbackGasLimit: callbackGasLimit,
            keyHash: keyHash
        });
        // 默认占位：用 block.prevrandao + requestId 派生
        if (preSeed[requestId] == 0) {
            preSeed[requestId] = uint256(keccak256(abi.encodePacked(block.prevrandao, requestId)));
        }
    }

    /// @notice 模拟 getRequestConfig：返回请求配置
    function getRequestConfig(uint256 requestId) external view override returns (uint16, uint32, bytes32) {
        RequestMeta memory m = requests[requestId];
        return (0, m.callbackGasLimit, m.keyHash);
    }

    /// @notice 测试用：预设某个 requestId 的随机数
    /// @dev 教学要点：测试前用 setSeed 设置预期值，避免依赖伪随机
    function setSeed(uint256 requestId, uint256 seed) external {
        preSeed[requestId] = seed;
    }

    /// @notice 测试用：触发"上一次请求"的 fulfill 回调
    /// @dev 教学要点：fulfillNextRandomWords 用于"提交最近一次请求"
    function fulfillNextRandomWords(address consumer) external {
        uint256 requestId = _nextRequestId - 1;
        uint256 seed = preSeed[requestId];
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        VRFConsumerBaseV2Callback(consumer).rawFulfillRandomWords(requestId, randomWords);
    }

    /// @notice 测试用：触发指定 requestId 的 fulfill 回调
    function fulfillRandomWords(uint256 requestId, address consumer) external {
        uint256 seed = preSeed[requestId];
        uint256[] memory randomWords = new uint256[](1);
        randomWords[0] = seed;
        VRFConsumerBaseV2Callback(consumer).rawFulfillRandomWords(requestId, randomWords);
    }

    /// @notice 返回最近一次分配的 requestId
    function latestRequestId() external view returns (uint256) {
        return _nextRequestId - 1;
    }
}

/**
 * @title VRFConsumerBaseV2Callback
 * @notice 回调接口：mock 直接调用消费者的 rawFulfillRandomWords
 * @dev 教学要点：
 *      1. mock 不继承 VRFConsumerBaseV2，仅需调用其 rawFulfillRandomWords
 *      2. 定义一个最小接口让 mock 可以 type-safe 调用
 */
interface VRFConsumerBaseV2Callback {
    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external;
}
