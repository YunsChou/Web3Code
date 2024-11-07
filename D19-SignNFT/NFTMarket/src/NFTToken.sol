// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./NFTPermit.sol";

contract NFTToken is ERC721, ERC721URIStorage, NFTPermit, Ownable {
    constructor() ERC721("YYNFTToken", "YYNFT") NFTPermit("EIP712Storage") Ownable(msg.sender) {}

    function tokenURI(uint256 tokenId) public view virtual override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    function mint(address to, uint256 tokenId, string memory uri) public onlyOwner {
        _mint(to, tokenId);
        _setTokenURI(tokenId, uri);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // 用来生成 签名消息
    function getPermitDigest(
        address _owner,
        address _spender,
        address _nftAddress,
        uint256 _nftTokenId,
        address _payToken,
        uint256 _payPrice,
        uint256 _deadline
    ) external view returns (bytes32 digest) {
        // 打包消息
        bytes32 permit_hash = keccak256(
            "Permit(address owner,address spender,address nftAddress,uint256 nftTokenId,address payToken,uint256 payPrice,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(permit_hash, _owner, _spender, _nftAddress, _nftTokenId, _payToken, _payPrice, _deadline)
        );

        digest = _hashTypedDataV4(structHash);
    }
}

/** 跟用户的交互流程：
1、seller授权nft给market
2、seller生成签名消息给market（从那里生成签名消息？需要私钥的，安全性）
3、market拿到签名消息进行挂单（如何获取签名中的信息？价格、deadline等；seller只提交signHash，会同时提供signHash+明文消息）
4、buyer买入nft（授权或callback），market给seller转erc20token，market给buyer转nft
 */
