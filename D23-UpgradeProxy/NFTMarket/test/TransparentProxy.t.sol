// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";

import "../src/NFTMarket.sol";
import "../src/NFTMarketV2.sol";
import "../src/TransparentProxy.sol";

contract TransparentProxyTest is Test {
    NFTMarket public nftMarket;
    NFTMarketV2 public nftMarketV2;
    TransparentProxy public upgradeProxy;

    function setUp() public {
        nftMarket = new NFTMarket();
        nftMarketV2 = new NFTMarketV2();

        upgradeProxy = new TransparentProxy(address(nftMarket));
    }

    function test_upgrade() public {
        // 升级前
        assertEq(upgradeProxy.implementation(), address(nftMarket), "implementation1 is error");

        // 升级后
        upgradeProxy.upgrade(address(nftMarketV2));
        assertEq(upgradeProxy.implementation(), address(nftMarketV2), "implementation2 is error");
    }
}
