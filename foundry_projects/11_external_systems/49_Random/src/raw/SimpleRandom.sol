// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

/**
 * @title SimpleRandom
 * @notice 演示链上随机数生成概念
 * @dev 这是本地/mock实现，仅用于展示原理。生产环境需要使用 Chainlink VRF 获取真正的随机数。
 */
contract SimpleRandom {

    /**
     * @notice 链上伪随机数生成
     * @dev 使用 keccak256 打包链上全局变量作为种子
     *      种子包含: blockhash(block.number-1), msg.sender, block.timestamp
     * @return uint256 伪随机数
     *
     * 注意: 此方法不安全，因为:
     * 1. 种子都是公开的，用户可以预测随机数
     * 2. 矿工可以操纵 blockhash 和 block.timestamp
     */
    function getRandomOnchain() public view returns (uint256) {
        bytes32 randomBytes = keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            msg.sender,
            block.timestamp
        ));
        return uint256(randomBytes);
    }

    /**
     * @notice 使用区块哈希生成随机数
     * @dev 直接使用单个区块的哈希作为随机源
     * @param blockNumber 要使用的区块号（必须是过去区块）
     * @return uint256 基于区块哈希的随机数
     */
    function getRandomFromBlockhash(uint256 blockNumber) public view returns (uint256) {
        require(blockNumber < block.number, "Block number must be in the past");
        bytes32 randomBytes = keccak256(abi.encodePacked(blockhash(blockNumber)));
        return uint256(randomBytes);
    }

    /**
     * @notice 生成指定范围内的随机数
     * @param min 最小值
     * @param max 最大值
     * @return uint256 指定范围内的随机数
     */
    function getRandomInRange(uint256 min, uint256 max) public view returns (uint256) {
        require(min < max, "Invalid range");
        uint256 random = getRandomOnchain();
        return min + (random % (max - min + 1));
    }

    /**
     * @notice 从数组中随机选择一个元素（模拟概念）
     * @dev 使用链上随机数选择索引
     * @param array 要选择的数组
     * @return uint256 选中的元素值
     */
    function pickRandomElement(uint256[] memory array) public view returns (uint256) {
        require(array.length > 0, "Empty array");
        uint256 random = getRandomOnchain();
        uint256 index = random % array.length;
        return array[index];
    }
}