// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC1363Receiver} from "@openzeppelin/contracts/interfaces/IERC1363Receiver.sol";
import "./NFTToken.sol";
import "./ERC20Token.sol";

struct NFTOrder {
    address seller;
    address nftToken;
    uint256 nftTokenId;
    address payToken;
    uint256 payPrice;
}

contract NFTMarket is IERC1363Receiver {
    uint256 public nftListIdx;
    mapping(uint256 => NFTOrder) public nftLists;

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

        nftLists[nftListIdx] = NFTOrder(msg.sender, nftAddress, nftTokenId, payToken, payPrice);
        emit NFTList(msg.sender, nftAddress, nftTokenId, payToken, payPrice);
        nftListIdx++;
    }

    function buyNFT(uint256 index) public {
        NFTOrder memory order = nftLists[index];
        require(order.seller != address(0), "NFT not listed");
        require(order.payToken != address(0), "NFT not listed");
        require(order.payPrice > 0, "NFT not listed");
        require(msg.sender != order.seller, "Seller cannot buy their own NFT");
        require(IERC20(order.payToken).balanceOf(msg.sender) >= order.payPrice, "Insufficient balance");

        IERC20(order.payToken).transferFrom(msg.sender, order.seller, order.payPrice);
        IERC721(order.nftToken).safeTransferFrom(order.seller, msg.sender, order.nftTokenId);

        emit NFTSold(msg.sender, order.nftToken, order.nftTokenId, order.payToken, order.payPrice);
        delete nftLists[index];
    }

    function onTransferReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        returns (bytes4)
    {
        (uint256 listIndex) = abi.decode(data, (uint256));

        NFTOrder memory order = nftLists[listIndex]; // 获取订单信息

        require(value >= order.payPrice, "receive cash amount is error");
        ERC20Token payToken = ERC20Token(order.payToken);
        // 限定调用者 token 类型
        require(msg.sender == address(payToken), "Only the specified token can call this");

        NFTToken nft = NFTToken(order.nftToken);
        // 交货：平台收到钱后，将钱转给卖家，将nft转给买家
        payToken.transfer(order.seller, order.payPrice); // 给钱

        nft.safeTransferFrom(order.seller, from, order.nftTokenId); // 给货

        // 多余的钱退还给用户
        if (value > order.payPrice) {
            payToken.transfer(operator, value - order.payPrice);
        }

        // 删除订单记录
        delete nftLists[listIndex];
        return NFTMarket.onTransferReceived.selector;
    }

    // function permitListNFT(
    //     address owner,
    //     address spender,
    //     address nftAddress,
    //     uint256 nftTokenId,
    //     address payToken,
    //     uint256 payPrice,
    //     uint256 deadline,
    //     uint8 v,
    //     bytes32 r,
    //     bytes32 s
    // ) public {
    //     require(owner == msg.sender, "is not owner");
    //     require(spender == address(this), "spender is no the bank contract");
    //     // 验签通过，并执行授权
    //     NFTToken nft = NFTToken(nftAddress);
    //     nft.permit(owner, spender, nftAddress, nftTokenId, payToken, payPrice, deadline, v, r, s);

    //     // 进行挂单
    //     listNFT(nftAddress, nftTokenId, payToken, payPrice);
    // }

    function permitBuyNFT(
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
    ) public {
        require(spender == address(this), "spender is no the market contract");

        // 验签通过，并执行授权
        NFTToken nft = NFTToken(nftAddress);
        nft.permit(owner, spender, nftAddress, nftTokenId, payToken, payPrice, deadline, v, r, s);

        IERC20(payToken).transferFrom(msg.sender, owner, payPrice);
        IERC721(nftAddress).safeTransferFrom(owner, msg.sender, nftTokenId);
    }
}
