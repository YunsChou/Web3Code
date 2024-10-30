// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";

contract NFTMarketScript is Script {
    NFTMarket public nftMarket;

    function setUp() public {}

    function run() external {
        vm.startBroadcast();
        nftMarket = new NFTMarket();
        vm.stopBroadcast();
    }
}
