// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "../src/NFTMarket.sol";
import "../src/NFTToken.sol";
import "../src/ERC20Token.sol";
import "forge-std/Test.sol";

contract NFTMarketTest is Test {
    NFTMarket nftMarket;
    NFTToken nftToken;
    ERC20Token erc20Token;
    address seller = makeAddr("alice");
    address buyer = makeAddr("bob");

    function setUp() public {
        nftMarket = new NFTMarket();
        nftToken = new NFTToken();
        erc20Token = new ERC20Token();

        erc20Token.mint(buyer, 1000);
        nftToken.mint(seller, 1, "uri");
    }

    function test_listNFT() public {
        vm.startPrank(seller);
        // 授权给市场
        nftToken.approve(address(nftMarket), 1);

        // 检查上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTList(seller, address(nftToken), 1, address(erc20Token), 100);

        // 上架
        nftMarket.listNFT(address(nftToken), 1, address(erc20Token), 100);

        // 检查上架结果
        assertEq(nftMarket.nftListIdx(), 1);
        (address seller_, address nftAddress_, uint256 tokenId_, address payToken_, uint256 price_) =
            nftMarket.nftLists(0);
        assertEq(seller_, seller);
        assertEq(nftAddress_, address(nftToken));
        assertEq(tokenId_, 1);
        assertEq(payToken_, address(erc20Token));
        assertEq(price_, 100);

        vm.stopPrank();
    }

    function test_buyNFT() public {
        vm.startPrank(seller);
        // 授权给市场
        nftToken.approve(address(nftMarket), 1);
        // 上架
        nftMarket.listNFT(address(nftToken), 1, address(erc20Token), 100);
        vm.stopPrank();

        vm.startPrank(buyer);
        // 授权给市场
        erc20Token.approve(address(nftMarket), 100);

        // 检查购买事件
        vm.expectEmit(true, true, true, true);
        emit NFTMarket.NFTSold(buyer, address(nftToken), 1, address(erc20Token), 100);

        // 购买
        nftMarket.buyNFT(0);

        // 检查购买结果
        assertEq(nftToken.ownerOf(1), buyer);
        assertEq(erc20Token.balanceOf(buyer), 900);
        assertEq(erc20Token.balanceOf(seller), 100);

        vm.stopPrank();
    }

    function test_onTransferReceived() external {
        // 授权挂单
        vm.startPrank(seller);
        nftToken.approve(address(nftMarket), 1);
        nftMarket.listNFT(address(nftToken), 1, address(erc20Token), 100);
        vm.stopPrank();

        // 购买
        vm.startPrank(buyer);
        bytes memory data = abi.encode(0);
        console.logBytes(data);
        erc20Token.transferAndCall(address(nftMarket), 100, data);
        vm.stopPrank();

        // 检查购买结果
        assertEq(nftToken.ownerOf(1), buyer);
        assertEq(erc20Token.balanceOf(buyer), 900);
        assertEq(erc20Token.balanceOf(seller), 100);
    }
}
