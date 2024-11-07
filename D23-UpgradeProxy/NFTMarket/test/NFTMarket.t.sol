// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "../src/NFTMarketV2.sol";
import "../src/NFTToken.sol";
import "../src/ERC20Token.sol";
import "forge-std/Test.sol";

contract NFTMarketTest is Test {
    NFTMarketV2 public nftMarket;
    NFTToken public nftToken;
    ERC20Token public erc20Token;

    uint256 public sellerPrivateKey;
    address public seller;
    address public buyer;

    function setUp() public {
        nftMarket = new NFTMarketV2();
        nftToken = new NFTToken();
        erc20Token = new ERC20Token();
        (seller, sellerPrivateKey) = makeAddrAndKey("alice");
        buyer = makeAddr("bob");

        erc20Token.mint(buyer, 1000);
        nftToken.mint(seller, 1, "uri");
    }

    function test_listNFT() public {
        vm.startPrank(seller);
        // 授权给市场
        nftToken.approve(address(nftMarket), 1);

        // 检查上架事件
        vm.expectEmit(true, true, true, true);
        emit NFTMarketV2.NFTList(seller, address(nftToken), 1, address(erc20Token), 100);

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
        emit NFTMarketV2.NFTSold(buyer, address(nftToken), 1, address(erc20Token), 100);

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

    function test_permitBuyNFT() public {
        // -------------------seller在中心化平台上填写，并保存到market中心化服务器------------------------
        uint256 time = block.timestamp + 1 hours;
        // 签名消息
        bytes32 msgHash = keccak256(
            abi.encodePacked(
                address(seller),
                address(nftMarket),
                address(nftToken),
                uint256(1),
                address(erc20Token),
                uint256(100),
                time
            )
        );
        bytes32 ethSignMsgHash = keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", msgHash));
        // 签名结果
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(sellerPrivateKey, ethSignMsgHash);
        // bytes memory signature = abi.encodePacked(r, s, v);
        // -------------------------------------------

        // 上架
        vm.startPrank(seller);
        // 授权给市场
        // nftToken.approve(address(nftMarket), 1);
        nftToken.setApprovalForAll(address(nftMarket), true);
        // 挂单上架
        // nftMarket.listNFT(address(nftToken), 1, address(erc20Token), 100);
        // ！！！在中心化平台上架
        vm.stopPrank();

        // 购买
        vm.startPrank(buyer);
        // 授权给市场
        erc20Token.approve(address(nftMarket), 100);
        // 拿到签名信息购买
        nftMarket.permitBuyNFT(
            address(seller), address(nftMarket), address(nftToken), 1, address(erc20Token), 100, time, v, r, s
        );
        vm.stopPrank();

        // 检查购买结果
        assertEq(nftToken.ownerOf(1), buyer);
        assertEq(erc20Token.balanceOf(buyer), 900);
        assertEq(erc20Token.balanceOf(seller), 100);
    }
}
