// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev ECDSA 库 - 用于签名验证
 */
library ECDSA {
    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(digest, v, r, s);
    }
}