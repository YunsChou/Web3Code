// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    PermitToken public moneyToken;
    NFToken public nftToken;

    address public seller;
    address public buyer;

    uint256 public buyerPrivateKey = 0x123;
    uint256 public sellerPrivateKey = 0xabc;

    function setUp() public {
        market = new NFTMarket();
        moneyToken = new PermitToken();
        nftToken = new NFToken();

        vm.label(address(market), "market-label");
        vm.label(address(moneyToken), "moneyToken-label");
        vm.label(address(nftToken), "nftToken-label");

        seller = vm.addr(sellerPrivateKey);
        buyer = vm.addr(buyerPrivateKey);

        nftToken.safeMint(seller, 1);

        moneyToken.mint(buyer, 10000 * 10 ** 18);
    }

    function test_tokenAmount() external view {
        console.log("-->> buyer balance:", moneyToken.balanceOf(buyer));
        assertEq(moneyToken.totalSupply(), 10000 * 10 ** 18, "totalSupply is error");
    }

    function testFail_listNotOwner() external {
        uint256 nftTokenId = 1;
        uint256 payPrice = 100;
        vm.prank(seller);
        // 授权到市场
        nftToken.approve(address(market), nftTokenId);

        // 市场进行挂单
        market.list(address(nftToken), nftTokenId, address(moneyToken), payPrice);
    }

    function test_list() external {
        uint256 nftTokenId = 1;
        uint256 payPrice = 100;
        vm.startPrank(seller);
        // 授权到市场
        nftToken.approve(address(market), nftTokenId);

        // 查询nft的授权地址
        address approver = nftToken.getApproved(nftTokenId);
        console.log("-->> tokenId: ", nftTokenId, " approver:", approver);
        assertEq(address(approver), address(market), "nft approve fail");

        // 测试事件
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTList(address(seller), address(nftToken), nftTokenId, payPrice);
        // 市场进行挂单
        market.list(address(nftToken), nftTokenId, address(moneyToken), payPrice);

        // 查询nft的持有人
        address nftOwner = nftToken.ownerOf(nftTokenId);
        console.log("-->> tokenId: ", nftTokenId, " nftOwner:", nftOwner);
        assertEq(address(nftOwner), address(market), "nft owner is error");

        // 查询市场挂单信息
        // mapping(uint256 => address) storage nftLists = market._nftList;
        // NFTOrder memory order = market._nftList[0];
        // console.log("-->> order.nftToke: ", market._nftList[0].nftToken);
        // assertEq(order.nftToken, nftToken, "nftToken is error");

        vm.stopPrank();
    }

    function test_buyNFT() external {
        uint256 nftTokenId = 1;
        uint256 payPrice = 100;
        // 卖
        vm.startPrank(seller);
        // 授权nft到市场
        nftToken.approve(address(market), nftTokenId);
        // 市场进行挂单
        market.list(address(nftToken), nftTokenId, address(moneyToken), payPrice);
        vm.stopPrank();

        uint256 listIndex = 1;
        // 买
        vm.startPrank(address(buyer));
        // 授权token到市场
        moneyToken.approve(address(market), payPrice);
        // 市场进行购买
        market.buyNFT(listIndex);
        // 查询nft的持有人
        address nftOwner = nftToken.ownerOf(nftTokenId);
        console.log("-->> tokenId: ", nftTokenId, " nftOwner:", nftOwner);
        assertEq(address(nftOwner), buyer, "nft owner is error");

        vm.stopPrank();
    }

    function test_onTransferReceived() external {
        uint256 listIndex = 1;
        uint256 nftTokenId = 1;
        uint256 payPrice = 100;
        // 卖家挂单
        vm.startPrank(seller);
        nftToken.approve(address(market), nftTokenId);
        market.list(address(nftToken), nftTokenId, address(moneyToken), payPrice);
        vm.stopPrank();

        // 测试事件
        // vm.expectEmit(true, true, true, true);
        // emit NFTMarket.NFTPurchase(address(seller), buyer, nftTokenId, payPrice);

        // 买家购买
        vm.startPrank(buyer);
        NFTOrder memory order = market.getNFTOrder(listIndex);
        console.log("-->> order.payToken: ", address(order.payToken));
        ERC1363((order.payToken)).transferAndCall(address(market), payPrice, abi.encode(listIndex));
        vm.stopPrank();

        // 查询nft的持有人
        address nftOwner = nftToken.ownerOf(nftTokenId);
        console.log("-->> tokenId: ", nftTokenId, " nftOwner:", nftOwner);
        assertEq(address(nftOwner), buyer, "nft owner is error");
    }

    //---------------------- permit buy ----------------------
    function testFail_permitBuyNotWhiteList() external {
        user_permitBuy();
    }

    function test_permitBuy() external {
        market.recordWhiteListUser(buyer);
        user_permitBuy();
    }

    function user_permitBuy() public {
        uint256 nftTokenId = 1;
        uint256 payPrice = 100;
        uint256 deadline = block.timestamp + 3 hours;
        // 卖
        vm.startPrank(seller);
        // 授权nft到市场
        nftToken.approve(address(market), nftTokenId);
        // 市场进行挂单
        market.list(address(nftToken), nftTokenId, address(moneyToken), payPrice);
        vm.stopPrank();

        uint256 listIndex = 1;
        // 买
        vm.startPrank(address(buyer));
        // 授权token到市场
        // moneyToken.approve(address(market), payPrice);
        bytes32 digest = moneyToken.getPermitDigest(buyer, address(market), payPrice, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPrivateKey, digest);
        // 市场进行购买
        market.permitBuy(listIndex, buyer, address(market), payPrice, deadline, v, r, s);
        // 查询nft的持有人
        address nftOwner = nftToken.ownerOf(nftTokenId);
        console.log("-->> tokenId: ", nftTokenId, " nftOwner:", nftOwner);
        assertEq(address(nftOwner), buyer, "nft owner is error");

        vm.stopPrank();
    }
}
