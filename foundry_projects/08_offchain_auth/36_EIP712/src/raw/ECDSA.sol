// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

/**
 * @dev ECDSA 库 - 用于签名验证
 */
library ECDSA {
    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function recoverSigner(bytes32 msgHash, bytes memory signature) internal pure returns (address) {
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return ecrecover(msgHash, v, r, s);
    }

    function verify(bytes32 msgHash, bytes memory signature, address signer) internal pure returns (bool) {
        return recoverSigner(msgHash, signature) == signer;
    }

    function recover(bytes32 digest, uint8 v, bytes32 r, bytes32 s) internal pure returns (address) {
        return ecrecover(digest, v, r, s);
    }
}