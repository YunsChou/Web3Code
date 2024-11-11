// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";
import "./MultiCall.sol";

import "./ERC20Token.sol";
import "./NFToken.sol";

contract AirdopMerkleNFTMarket is MultiCall {
    struct NFTOrder {
        address owner;
        uint256 tokenId;
        uint256 price;
    }

    ERC20Token public token;
    NFToken public nft;
    bytes32 public merkleRoot;
    mapping(uint256 => NFTOrder) public nftOrders;
    uint256 public nftOrderCount;

    constructor(address _token, address _nft, bytes32 _merkleRoot) {
        token = ERC20Token(_token);
        nft = NFToken(_nft);
        merkleRoot = _merkleRoot;
    }

    // 挂单nft
    function listNFT(uint256 tokenId, uint256 price) external {
        // 检查tokenId所有者
        require(nft.ownerOf(tokenId) == msg.sender, "Not owner of tokenId");
        // 检查nft是否授权
        require(nft.getApproved(tokenId) == address(this), "NFT not approved");
        // 检查价格
        require(price > 0, "Price must be greater than 0");

        nftOrders[nftOrderCount] = NFTOrder(msg.sender, tokenId, price);
        nftOrderCount++;
    }

    // 使用calldata方式
    function permitPrePayAndClaimNFT(bytes[] calldata datas) external returns (bytes[] memory) {
        return multiDelegateCall(datas);
    }

    // -------------------------常规调用验证-------------------------
    // token Permit授权
    function permitPrePay(uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external {
        console.log("-->> permitPrePay: %s", value);
        token.permit(msg.sender, address(this), value, deadline, v, r, s);
        // token.transferFrom(owner, address(this), value);
    }

    // 通过merkle tree验证白名单，进行交易
    function claimNFT(uint256 orderIndex, bytes32[] memory proof) external {
        // 通过merkle tree验证白名单
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");

        // 检查订单是否存在
        require(nftOrders[orderIndex].owner != address(0), "Order not found");
        NFTOrder memory order = nftOrders[orderIndex];

        // 检查tokken授权额度
        require(token.allowance(msg.sender, address(this)) >= order.price / 2, "Insufficient allowance");
        // 检查nft是否授权
        require(nft.getApproved(order.tokenId) == address(this), "NFT not approved");
        // 以nftOrder价格的一半购买
        token.transferFrom(msg.sender, order.owner, order.price / 2);
        // 交货
        nft.transferFrom(order.owner, msg.sender, order.tokenId);

        // 删除订单
        delete nftOrders[orderIndex];
    }
}
