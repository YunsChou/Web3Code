// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";

import "../src/NFTMarket.sol";
import "../src/TransparentProxy.sol";

contract TransparentProxyScript is Script {
    NFTMarket public nftMarket;
    TransparentProxy public upgradeProxy;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        nftMarket = new NFTMarket();

        upgradeProxy = new TransparentProxy(address(nftMarket));

        vm.stopBroadcast();
    }
}
