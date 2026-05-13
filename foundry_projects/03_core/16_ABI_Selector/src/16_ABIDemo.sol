// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

contract ABIDemo {
    struct User {
        uint256 uid;
        bytes name;
    }

    // 基础 encode/decode
    function encodeValues() external pure returns (bytes memory) {
        return abi.encode(uint256(1), address(0x123));
    }

    function decodeValues(bytes memory _data) external pure returns (uint256, address) {
        return abi.decode(_data, (uint256, address));
    }

    // encodeWithSignature
    function encodeWithSig() external pure returns (bytes memory) {
        return abi.encodeWithSignature("mint(address,uint256)", address(0x123), 100);
    }

    // Selector 计算
    function getSelector() external pure returns (bytes4) {
        return bytes4(keccak256("mint(address,uint256)"));
    }
}
