// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./NFTToken.sol";
import "./ERC20Token.sol";

struct NFTOrder {
    address seller;
    address nftAddress;
    uint256 nftTokenId;
    address payToken;
    uint256 payPrice;
}

contract NFTMarket {
    uint256 public nftlistindex;
    mapping(uint256 => NFTOrder) public nftlist;

    event NFTList(
        address indexed seller,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address payToken,
        uint256 payPrice
    );
    event NFTSold(
        address indexed buyer,
        address indexed nftAddress,
        uint256 indexed nftTokenId,
        address payToken,
        uint256 payPrice
    );

    function listNFT(address nftAddress, uint256 nftTokenId, address payToken, uint256 payPrice) public {
        require(nftAddress != address(0), "Invalid NFT address");
        require(payToken != address(0), "Invalid payment token address");
        require(payPrice > 0, "Price must be greater than 0");
        require(IERC721(nftAddress).ownerOf(nftTokenId) == msg.sender, "Only NFT owner can list");
        require(IERC721(nftAddress).getApproved(nftTokenId) == address(this), "NFT not approved for transfer");

        nftlist[nftlistindex] = NFTOrder(msg.sender, nftAddress, nftTokenId, payToken, payPrice);
        emit NFTList(msg.sender, nftAddress, nftTokenId, payToken, payPrice);
        nftlistindex++;
    }

    function buyNFT(uint256 index) public {
        NFTOrder memory order = nftlist[index];
        require(order.seller != address(0), "NFT not listed");
        require(order.payToken != address(0), "NFT not listed");
        require(order.payPrice > 0, "NFT not listed");
        require(msg.sender != order.seller, "Seller cannot buy their own NFT");
        require(IERC20(order.payToken).balanceOf(msg.sender) >= order.payPrice, "Insufficient balance");

        IERC20(order.payToken).transferFrom(msg.sender, order.seller, order.payPrice);
        IERC721(order.nftAddress).safeTransferFrom(order.seller, msg.sender, order.nftTokenId);

        emit NFTSold(msg.sender, order.nftAddress, order.nftTokenId, order.payToken, order.payPrice);
        delete nftlist[index];
    }
}
