// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";

import "../src/NFTMarket.sol";

contract NFTMarketScript is Script {
    NFTMarket public market;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        market = new NFTMarket();

        vm.stopBroadcast();
    }
}
