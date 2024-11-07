// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/ERC20Token.sol";
import "../src/NFTToken.sol";
import "../src/NFTMarket.sol";

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    NFTToken public nftToken;
    ERC20Token public erc20Token;

    uint256 public privateKey;
    address public seller;
    address public buyer = makeAddr("bob");

    function setUp() public {
        nftMarket = new NFTMarket();
        nftToken = new NFTToken();
        erc20Token = new ERC20Token();
        (seller, privateKey) = makeAddrAndKey("alice");

        nftToken.mint(seller, 1, "uri");
        erc20Token.mint(buyer, 1000);
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

    function test_permitBuyNFT() public {
        // -------------------seller在中心化平台上填写，并保存到market中心化服务器------------------------
        uint256 time = block.timestamp + 1 hours;
        // 签名消息
        bytes32 digest = nftToken.getPermitDigest(
            address(seller), address(nftMarket), address(nftToken), 1, address(erc20Token), 100, time
        );
        // 使用私钥签名, 获取 rsv
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, digest);
        // -------------------------------------------

        // 上架
        vm.startPrank(seller);
        // 授权给市场
        nftToken.approve(address(nftMarket), 1);
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

    /* 自己构建的签名信息，和使用 ERC721 构建的签名信息不一致
    function getCustomPermitDigest() public view {
        uint256 time = block.timestamp + 1 hours;
        // 签名消息
        bytes32 permit_hash = keccak256(
            "Permit(address owner,address spender,address nftAddress,uint256 nftTokenId,address payToken,uint256 payPrice,uint256 deadline)"
        );
        bytes32 structHash = keccak256(
            abi.encode(
                permit_hash, address(seller), address(nftMarket), address(nftToken), 1, address(erc20Token), 100, time
            )
        );

        bytes32 domain_hash =
            keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

        bytes32 domainSeparator = keccak256(
            abi.encode(
                domain_hash, keccak256(bytes("EIP712Storage")), keccak256(bytes("1")), block.chainid, address(this)
            )
        );
        bytes32 msgHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        console.logBytes32(msgHash);
    }
    */
}
