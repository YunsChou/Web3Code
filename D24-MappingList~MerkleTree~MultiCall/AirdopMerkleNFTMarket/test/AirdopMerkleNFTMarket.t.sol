// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/AirdopMerkleNFTMarket.sol";
import "../src/ERC20Token.sol";
import "../src/NFToken.sol";

contract AirdopMerkleNFTMarketTest is Test {
    AirdopMerkleNFTMarket public market;
    ERC20Token public token;
    NFToken public nft;

    uint256 public buyerPk = 0x123;
    // 模拟生成merkle tree的4个地址
    address buyer = vm.addr(buyerPk);
    address seller = makeAddr("seller");
    address user3 = makeAddr("user3");
    address user4 = makeAddr("user4");

    /**
     * 使用 https://lab.miguelmota.com/merkletreejs/example/  生成
     *   buyer 0x476C88ED464EFD251a8b18Eb84785F7C46807873
     *   seller 0xDFa97bfe5d2b2E8169b194eAA78Fbb793346B174
     *   user3 0xc0A55e2205B289a967823662B841Bd67Aa362Aec
     *   user4 0x90561e5Cd8025FA6F52d849e8867C14A77C94BA0
     *
     * Tree
     * └─ bc975aee5b9d7da8b1ff9232e50f662daadb00c028b8e083fa7f02ebdbac08d0
     *    ├─ af8fef0ea73fe3829825f4d1765f10bc21ab77bc11506e2e652176f2c8fa2dfd
     *    │  ├─ 782055b277e596931f0261e06456c77518c92ebf42dd2b335256499c1ae38a1b
     *    │  └─ 08ec96d6034d3935708da7267d4b46eff7f3c90c76162e89344bc157f6d073f7
     *    └─ 99ee7d1d978da17c87b2b35fa00025d7b13eef1cbcfe3242d757f00cdb89c777
     *   ├─ d66ef8fcbb58f354c4524d02759073f4d381952ab2c569249eb87fc6d604190e
     *   └─ 9da491e4739d81339aa2ea8cd1894378b835f73b1288628dda5b082f9562c409
     */
    bytes32 merkleRoot = 0xbc975aee5b9d7da8b1ff9232e50f662daadb00c028b8e083fa7f02ebdbac08d0;
    bytes32[] public proof = [
        bytes32(0x08ec96d6034d3935708da7267d4b46eff7f3c90c76162e89344bc157f6d073f7),
        bytes32(0x99ee7d1d978da17c87b2b35fa00025d7b13eef1cbcfe3242d757f00cdb89c777)
    ];

    function setUp() public {
        token = new ERC20Token();
        nft = new NFToken();
        market = new AirdopMerkleNFTMarket(address(token), address(nft), merkleRoot);

        console.log("buyer", buyer);
        console.log("seller", seller);
        console.log("user3", user3);
        console.log("user4", user4);

        // 给buyer转1000个token
        deal(address(token), buyer, 1000);

        // seller铸造nft
        nft.mint(seller, 1);

        bytes32 leaf = keccak256(abi.encodePacked(buyer));
        console.log("buyer leaf");
        console.logBytes32(leaf);
    }

    function test_listNFT() public {
        // 调用listNFT
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(1, 100);
        vm.stopPrank();
        // 检查market的nftOrderCount
        assertEq(market.nftOrderCount(), 1);
        // 检查market的nftOrders
        (, uint256 tokenId, uint256 price) = market.nftOrders(0);
        assertEq(tokenId, 1);
        assertEq(price, 100);
    }

    function test_permitPrePay() public {
        uint256 deadline = block.timestamp + 1 days;
        uint256 value = 100;
        // 模拟permit签名消息
        bytes32 digest = token.getPermitDigest(buyer, address(market), value, deadline);

        // 模拟签名
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(buyerPk, digest);

        // 调用permitPrePay
        vm.prank(buyer);
        market.permitPrePay(value, deadline, v, r, s);

        // 检查market的授权额度
        assertEq(token.allowance(buyer, address(market)), value);
    }

    function test_claimNFT() public {
        // 模拟seller挂单
        vm.startPrank(seller);
        nft.approve(address(market), 1);
        market.listNFT(1, 100);
        vm.stopPrank();

        // 模拟buyer授权额度
        vm.startPrank(buyer);
        token.approve(address(market), 100);
        // 调用claimNFT
        market.claimNFT(0, proof);
        vm.stopPrank();

        // 检查buyer的nft
        assertEq(nft.ownerOf(1), buyer);
        // 检查market的nftOrders
        (, uint256 tokenId, uint256 price) = market.nftOrders(0);
        assertEq(tokenId, 0);
        assertEq(price, 0);
        // 检查buyer的token
        assertEq(token.balanceOf(buyer), 1000 - 100 / 2);
        // 检查seller的token
        assertEq(token.balanceOf(seller), 100 / 2);
    }
}
