// SPDX-License-Identifier: MIT
pragma solidity ^0.8.35;

import {ERC721} from "./ERC721.sol";
import {ECDSA} from "./ECDSA.sol";

/**
 * @dev SignatureNFT 合约 - 原生实现
 * 利用 ECDSA 签名验证发放 NFT 白名单
 */
contract SignatureNFT is ERC721 {
    address public immutable signer;
    mapping(address => bool) public mintedAddress;

    constructor(address _signer) {
        signer = _signer;
    }

    function mint(address _account, uint256 _tokenId, bytes memory _signature) external {
        bytes32 _msgHash = getMessageHash(_account, _tokenId);
        bytes32 _ethSignedMessageHash = ECDSA.toEthSignedMessageHash(_msgHash);
        require(verify(_ethSignedMessageHash, _signature), "Invalid signature");
        require(!mintedAddress[_account], "Already minted!");

        mintedAddress[_account] = true;
        _mint(_account, _tokenId);
    }

    function getMessageHash(address _account, uint256 _tokenId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_account, _tokenId));
    }

    function verify(bytes32 _msgHash, bytes memory _signature) public view returns (bool) {
        return ECDSA.verify(_msgHash, _signature, signer);
    }
}