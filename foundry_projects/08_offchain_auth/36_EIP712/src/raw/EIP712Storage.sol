// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ECDSA} from "./ECDSA.sol";

/**
 * @dev EIP712 类型化数据签名合约 - 原生实现
 */
contract EIP712Storage {
    using ECDSA for bytes32;

    bytes32 private constant EIP712DOMAIN_TYPEHASH = keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");
    bytes32 private constant STORAGE_TYPEHASH = keccak256("Storage(address spender,uint256 number)");
    bytes32 public DOMAIN_SEPARATOR;
    uint256 public number;
    address public owner;

    constructor(address _owner) {
        DOMAIN_SEPARATOR = keccak256(abi.encode(
            EIP712DOMAIN_TYPEHASH,
            keccak256(bytes("EIP712Storage")),
            keccak256(bytes("1")),
            block.chainid,
            address(this)
        ));
        owner = _owner;
    }

    function permitStore(uint256 _num, bytes memory _signature) public {
        require(_signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(_signature, 0x20))
            s := mload(add(_signature, 0x40))
            v := byte(0, mload(add(_signature, 0x60)))
        }

        bytes32 digest = keccak256(abi.encodePacked(
            "\x19\x01",
            DOMAIN_SEPARATOR,
            keccak256(abi.encode(STORAGE_TYPEHASH, msg.sender, _num))
        ));

        address signer = digest.recover(v, r, s);
        require(signer == owner, "EIP712Storage: Invalid signature");

        number = _num;
    }

    function retrieve() public view returns (uint256) {
        return number;
    }
}