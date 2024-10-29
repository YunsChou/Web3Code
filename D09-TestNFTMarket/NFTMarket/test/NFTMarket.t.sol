// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    NFTMarket public market;
    ERC20Token public moneyToken;
    NFToken public nftToken;

    address public seller;
    address public buyer;

    function setUp() public {
        market = new NFTMarket();
        moneyToken = new ERC20Token();
        nftToken = new NFToken();

        vm.label(address(market), "market-label");
        vm.label(address(moneyToken), "moneyToken-label");
        vm.label(address(nftToken), "nftToken-label");

        console.log("-->> market: ", address(market));
        console.log("-->> moneyToken: ", address(moneyToken));
        console.log("-->> nftToken: ", address(nftToken));

        seller = address(1);
        buyer = address(2);

        nftToken.safeMint(seller, 1);
        nftToken.safeMint(seller, 2);
        nftToken.safeMint(seller, 3);

        moneyToken.transfer(buyer, 1000 * 10 ** 18);
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
        assertEq(address(nftOwner), address(seller), "nft owner is error");

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
}
