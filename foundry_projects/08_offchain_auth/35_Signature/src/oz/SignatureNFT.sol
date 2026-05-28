// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

/**
 * @dev OpenZeppelin SignatureNFT 合约
 */
contract SignatureNFTOZ is ERC721 {
    address public immutable signer;
    mapping(address => bool) public mintedAddress;

    constructor(address _signer, string memory name, string memory symbol) ERC721(name, symbol) {
        signer = _signer;
    }

    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId);
        bytes32 _ethSignedMessageHash = toEthSignedMessageHash(_msgHash);
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");
        require(!mintedAddress[_account], "Already minted!");

        mintedAddress[_account] = true;
        _mint(_account, _tokenId);
    }

    function getMessageHash(address _account, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    function toEthSignedMessageHash(bytes32 hash) public pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

    function verify(bytes32 msgHash, bytes memory signature) public view returns (bool) {
        require(signature.length == 65, "invalid signature length");
        bytes32 r;
        bytes32 s;
        uint8 v;
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        return ecrecover(msgHash, v, r, s) == signer;
    }
}