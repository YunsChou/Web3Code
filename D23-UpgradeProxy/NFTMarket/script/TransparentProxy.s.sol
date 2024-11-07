// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import "../src/NFTMarket.sol";
import "../src/TransparentProxy.sol";

import "../src/NFTMarketV2.sol";

contract TransparentProxyScript is Script {
    // NFTMarket public nftMarket;
    TransparentProxy public upgradeProxy;

    NFTMarketV2 public nftMarketV2;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();
        // V1
        // nftMarket = new NFTMarket();
        // upgradeProxy = new TransparentProxy(address(nftMarket));
        // 透明代理地址 0x0d960351a9722C135078057e4298A29702C449f3
        address proxyContract = 0x0d960351a9722C135078057e4298A29702C449f3;
        // V2
        nftMarketV2 = new NFTMarketV2();
        (bool succ,) = address(proxyContract).call(abi.encodeWithSignature("upgrade(address)", address(nftMarketV2)));
        require(succ, "call upgrade fail");

        vm.stopBroadcast();
    }
}
