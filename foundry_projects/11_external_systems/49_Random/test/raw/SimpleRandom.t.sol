// SPDX-License-Identifier: MIT
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "../../src/raw/SimpleRandom.sol";

/**
 * @title SimpleRandomTest
 * @notice 原生实现 SimpleRandom（伪随机数）的单元测试
 * @dev 教学重点（务必阅读）：
 *      1. 链上伪随机数是"不安全"的演示：
 *         - blockhash / block.timestamp / block.prevrandao 均可被矿工/验证者操纵
 *         - 攻击者可预测或影响结果
 *         - 真实场景务必使用 Chainlink VRF 或其他可验证随机源
 *      2. 教学意义：理解"链上无真随机"的本质
 *      3. 本合约提供的方法：
 *         - getRandomOnchain(): 用 prevrandao + msg.sender + gas 等组合
 *         - getRandomFromBlockhash(num): 用历史区块哈希
 *         - getRandomInRange(min, max): 范围限制
 *         - pickRandomElement(arr): 数组随机选一个
 *      4. Foundry cheatcode:
 *         - vm.roll(blockNum): 设置 block.number
 *         - vm.warp(timestamp): 设置 block.timestamp
 */
contract SimpleRandomTest is Test {
    SimpleRandom public simpleRandom;

    function setUp() public {
        simpleRandom = new SimpleRandom();
    }

    /// @notice 验证 getRandomOnchain 返回正数
    /// @dev 教学要点：两次连续调用可能得到相同结果（同一区块），但实际随机性应足够分散
    function testGetRandomOnchain() public {
        uint256 random1 = simpleRandom.getRandomOnchain();
        uint256 random2 = simpleRandom.getRandomOnchain();

        // 随机数应大于 0
        assertGt(random1, 0);
        assertGt(random2, 0);
    }

    /// @notice 验证 getRandomFromBlockhash 从历史区块派生随机数
    function testGetRandomFromBlockhash() public {
        // 用前一区块哈希
        uint256 random = simpleRandom.getRandomFromBlockhash(block.number - 1);
        assertGt(random, 0);
    }

    /// @notice 验证用未来区块哈希必须 revert
    /// @dev 教学要点：未来区块哈希不可知，传未来 num 必失败
    function testGetRandomFromBlockhashFailsForFutureBlock() public {
        vm.expectRevert("Block number must be in the past");
        simpleRandom.getRandomFromBlockhash(block.number + 1);
    }

    /// @notice 验证 getRandomInRange 返回 [min, max] 范围内的数
    function testGetRandomInRange() public {
        uint256 min = 10;
        uint256 max = 100;

        uint256 random = simpleRandom.getRandomInRange(min, max);

        // 范围断言
        assertGe(random, min);
        assertLe(random, max);
    }

    /// @notice 验证 min > max 时 revert
    function testGetRandomInRangeInvalidRange() public {
        uint256 min = 100;
        uint256 max = 10;

        vm.expectRevert("Invalid range");
        simpleRandom.getRandomInRange(min, max);
    }

    /// @notice 验证 pickRandomElement 返回数组中的某个元素
    /// @dev 教学要点：循环遍历数组校验所选元素确实在数组中
    function testPickRandomElement() public {
        uint256[] memory array = new uint256[](5);
        array[0] = 10;
        array[1] = 20;
        array[2] = 30;
        array[3] = 40;
        array[4] = 50;

        uint256 selected = simpleRandom.pickRandomElement(array);

        // 校验所选元素在数组中
        bool found = false;
        for (uint256 i = 0; i < array.length; i++) {
            if (array[i] == selected) {
                found = true;
                break;
            }
        }
        assertTrue(found, "Selected element not in array");
    }

    /// @notice 验证空数组必须 revert
    function testPickRandomElementEmptyArray() public {
        uint256[] memory array = new uint256[](0);

        vm.expectRevert("Empty array");
        simpleRandom.pickRandomElement(array);
    }

    /// @notice 验证不同区块产生不同随机数
    /// @dev 教学要点：vm.roll 推进 block.number，vm.warp 推进 block.timestamp
    function testRandomnessUniqueness() public {
        uint256 randomBefore = simpleRandom.getRandomOnchain();

        // 推进区块
        vm.roll(block.number + 1);
        vm.warp(block.timestamp + 12);

        uint256 randomAfter = simpleRandom.getRandomOnchain();

        // 不同区块的随机数应当不同
        assertTrue(randomBefore != randomAfter, "Random numbers should differ between blocks");
    }
}
