// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";

import "../src/NFTMarketV2.sol";

contract NFTMarketV2Script is Script {
    NFTMarketV2 public market;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        market = new NFTMarketV2();

        vm.stopBroadcast();
    }
}
