// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

abstract contract NFTPermit is ERC721, EIP712 {
    error ERC721PermitExpiredSignature(uint256 deadline);
    error ERC721PermitInvalidSigner(address signer, address owner);

    bytes32 private constant PERMIT_TYPEHASH = keccak256(
        "Permit(address owner,address spender,address nftAddress,uint256 nftTokenId,address payToken,uint256 payPrice,uint256 deadline)"
    );

    constructor(string memory _name) EIP712(_name, "1") {}

    function permit(
        address owner,
        address spender,
        address nftAddress,
        uint256 nftTokenId,
        address payToken,
        uint256 payPrice,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public virtual {
        if (block.timestamp > deadline) {
            revert ERC721PermitExpiredSignature(deadline);
        }

        bytes32 structHash =
            keccak256(abi.encode(PERMIT_TYPEHASH, owner, spender, nftAddress, nftTokenId, payToken, payPrice, deadline));

        bytes32 hash = _hashTypedDataV4(structHash);

        address signer = ECDSA.recover(hash, v, r, s);
        if (signer != owner) {
            revert ERC721PermitInvalidSigner(signer, owner);
        }
    }
}
