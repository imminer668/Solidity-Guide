// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title IVRFCoordinatorV2
 * @notice Chainlink VRF v2 协调器接口（精简版）
 * @dev 此处只包含 OZ 实现所需的最小接口，与官方 VRFCoordinatorV2Interface 兼容
 */
interface IVRFCoordinatorV2 {
    function requestRandomWords(
        bytes32 keyHash,
        uint64 subId,
        uint16 minimumRequestConfirmations,
        uint32 callbackGasLimit,
        uint32 numWords
    ) external returns (uint256 requestId);

    function getRequestConfig(uint256 requestId) external view returns (uint16, uint32, bytes32);
}

/**
 * @title VRFConsumerBaseV2
 * @notice Chainlink VRF v2 消费者基类（精简版）
 * @dev 实现与官方 VRFConsumerBaseV2 相同的接口。
 *      仅包含 fulfillRandomWords 与 rawFulfillRandomWords 方法，
 *      足够 OZ 实现的 SimpleRandomOZ 继承并接收回调。
 */
abstract contract VRFConsumerBaseV2 {
    error OnlyCoordinatorCanFulfill(address have, address want);

    address public immutable vrfCoordinator;

    constructor(address _vrfCoordinator) {
        vrfCoordinator = _vrfCoordinator;
    }

    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal virtual;

    function rawFulfillRandomWords(uint256 requestId, uint256[] memory randomWords) external {
        if (msg.sender != vrfCoordinator) {
            revert OnlyCoordinatorCanFulfill(msg.sender, vrfCoordinator);
        }
        fulfillRandomWords(requestId, randomWords);
    }
}