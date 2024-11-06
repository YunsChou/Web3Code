// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./NFToken.sol";
import "./ERC20Token.sol";

contract NFTMarket is IERC20Receiver {
    struct NFTOrder {
        address owner; // nft持有人
        address nftToken; // nft合约
        uint256 nftTokenId; // nft tokenId
        address payToken; // erc20代币合约
        uint256 payPrice; // 代币数量
    }

    uint256 public nftListIndex; // 订单编号
    mapping(uint256 => NFTOrder) public _nftList; // nft 订单

    event RecordAbiEncode(bytes indexed enData);

    // 上架
    function list(address nftAddress, uint256 tokenId, address tokenAdress, uint256 price) external {
        NFToken nft = NFToken(nftAddress);
        address owner = nft.ownerOf(tokenId);
        require(owner == msg.sender, "is not owner"); // 操作中是本人
        require(nft.getApproved(tokenId) == address(this), "is not appoved market"); // 已经授权当前合约
        require(price > 0, "price must > 0"); // 设置价格 > 0
        // 创建订单
        NFTOrder memory order = NFTOrder(owner, nftAddress, tokenId, tokenAdress, price);
        nftListIndex++;
        _nftList[nftListIndex] = order;
        // 将NFT转到合约（订单持有者变为当前合约）
        nft.safeTransferFrom(msg.sender, address(this), tokenId, abi.encode(order));

        emit RecordAbiEncode(abi.encode(1));
    }

    // 购买方式1：普通购买（先授权，后购买）
    function buyNFT(uint256 listIndex) external {
        require(listIndex <= nftListIndex, "invalid order index"); // 错误的订单
        NFTOrder memory order = _nftList[listIndex]; // 获取订单信息

        NFToken nft = NFToken(order.nftToken); // nft 信息
        address nftOwner = nft.ownerOf(order.nftTokenId);

        require(nftOwner == address(this), "invalid order owner"); // 订单持有者是当前合约

        ERC20Token payToken = ERC20Token(order.payToken);
        // 授权给平台的额度是否足够
        require(payToken.allowance(msg.sender, address(this)) >= order.payPrice, "allowance not enought");

        // 平台将钱转到卖家帐户
        payToken.transferFrom(msg.sender, nftOwner, order.payPrice);
        // 将nft转到买家帐户
        nft.safeTransferFrom(nftOwner, msg.sender, order.nftTokenId);

        // 删除订单记录
        delete _nftList[listIndex];
    }

    // 接收nft
    // function onERC721Received(
    //     address ,
    //     address ,
    //     uint256 ,
    //     bytes calldata
    // ) external pure  returns (bytes4) {
    //     return NFTMarket.onERC721Received.selector;
    // }

    // 购买方式2：钩子函数（用户直接往mark合约转账购买）
    // 这里的
    function tokensReceived(address operator, address from, uint256 amount, bytes calldata data)
        external
        returns (bytes4)
    {
        (uint256 listIndex) = abi.decode(data, (uint256));
        NFTOrder memory order = _nftList[listIndex]; // 获取订单信息
        require(amount >= order.payPrice, "receive cash amount is error");
        ERC20Token payToken = ERC20Token(order.payToken);
        // 限定调用者 token 类型
        require(msg.sender == address(payToken), "Only the specified token can call this");

        NFToken nft = NFToken(order.nftToken);
        // 交货：平台收到钱后，将钱转给卖家，将nft转给买家
        payToken.transfer(order.owner, order.payPrice); // 给钱

        nft.safeTransferFrom(address(this), from, order.nftTokenId); // 给货

        // 多余的钱退还给用户
        if (amount > order.payPrice) {
            payToken.transfer(operator, amount - order.payPrice);
        }

        // 删除订单记录
        delete _nftList[listIndex];
        return NFTMarket.tokensReceived.selector;
    }
}
