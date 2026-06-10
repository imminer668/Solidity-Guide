// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IVRFCoordinatorV2, VRFConsumerBaseV2} from "./VRFConsumerBaseV2.sol";

/**
 * @title SimpleRandomOZ
 * @notice 基于 Chainlink VRF v2 的随机数消费合约
 * @dev 演示 OpenZeppelin 项目中接入 Chainlink VRF 的标准模式：
 *      1. 用户调用 requestRandom() 提交请求
 *      2. 合约向 VRFCoordinator 发起 requestRandomWords
 *      3. Chainlink 预言机回调 fulfillRandomWords 提供可验证随机数
 *      4. 用户通过 getRandomResult(requestId) 获取结果
 *
 * 注意：此项目使用自包含的 VRFConsumerBaseV2 实现（见 ./VRFConsumerBaseV2.sol），
 *      兼容 Chainlink 官方 VRFConsumerBaseV2 接口。
 *      生产环境替换为 Chainlink 部署的 VRFCoordinator 即可。
 */
contract SimpleRandomOZ is VRFConsumerBaseV2, Ownable {
    struct RequestConfig {
        uint64 subId;
        uint32 callbackGasLimit;
        uint16 requestConfirmations;
    }

    RequestConfig public requestConfig;
    bytes32 public keyHash;

    mapping(uint256 => address) public requestToRequester;
    mapping(uint256 => uint256) public requestToRandom;
    mapping(address => uint256[]) public userRequests;

    event RandomRequested(uint256 indexed requestId, address indexed requester);
    event RandomFulfilled(uint256 indexed requestId, address indexed requester, uint256 randomWord);

    error RequestNotFound(uint256 requestId);
    error RequestNotFulfilled(uint256 requestId);

    constructor(
        address _vrfCoordinator,
        bytes32 _keyHash,
        uint64 _subId,
        uint32 _callbackGasLimit,
        uint16 _requestConfirmations
    ) VRFConsumerBaseV2(_vrfCoordinator) Ownable(msg.sender) {
        keyHash = _keyHash;
        requestConfig = RequestConfig({
            subId: _subId,
            callbackGasLimit: _callbackGasLimit,
            requestConfirmations: _requestConfirmations
        });
    }

    /**
     * @notice 设置 VRF 订阅配置参数
     * @dev 业主可调整 confirmations 与 gas 限制以平衡成本与安全
     */
    function setRequestConfig(uint64 _subId, uint32 _callbackGasLimit, uint16 _requestConfirmations) external onlyOwner {
        requestConfig = RequestConfig({
            subId: _subId,
            callbackGasLimit: _callbackGasLimit,
            requestConfirmations: _requestConfirmations
        });
    }

    function setKeyHash(bytes32 _keyHash) external onlyOwner {
        keyHash = _keyHash;
    }

    /**
     * @notice 用户申请一个可验证随机数
     * @return requestId Chainlink VRF 请求 ID
     */
    function requestRandom() external returns (uint256 requestId) {
        RequestConfig memory cfg = requestConfig;
        requestId = IVRFCoordinatorV2(vrfCoordinator).requestRandomWords(
            keyHash,
            cfg.subId,
            cfg.requestConfirmations,
            cfg.callbackGasLimit,
            1
        );

        requestToRequester[requestId] = msg.sender;
        userRequests[msg.sender].push(requestId);

        emit RandomRequested(requestId, msg.sender);
    }

    /**
     * @notice Chainlink 协调器回调入口
     * @dev 真实环境中由 Chainlink 预言机调用；本项目中由 mock 触发
     */
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {
        address requester = requestToRequester[requestId];
        require(requester != address(0), "Invalid request");

        uint256 randomWord = randomWords[0];
        requestToRandom[requestId] = randomWord;

        emit RandomFulfilled(requestId, requester, randomWord);
    }

    /**
     * @notice 获取某次请求的随机数结果
     * @param requestId VRF 请求 ID
     * @return 0 到 2^256-1 之间的随机数
     */
    function getRandomResult(uint256 requestId) external view returns (uint256) {
        uint256 random = requestToRandom[requestId];
        if (requestToRequester[requestId] == address(0)) revert RequestNotFound(requestId);
        if (random == 0) revert RequestNotFulfilled(requestId);
        return random;
    }

    /**
     * @notice 获取某地址的所有请求 ID
     */
    function getUserRequests(address user) external view returns (uint256[] memory) {
        return userRequests[user];
    }
}