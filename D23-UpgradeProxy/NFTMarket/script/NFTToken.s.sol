// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {NFTToken} from "../src/NFTToken.sol";

contract NFTTokenScript is Script {
    NFTToken public nft;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        nft = new NFTToken();

        vm.stopBroadcast();
    }
}
