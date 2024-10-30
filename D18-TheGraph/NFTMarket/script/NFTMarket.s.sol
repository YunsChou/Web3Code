// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {NFTMarket} from "../src/NFTMarket.sol";
import {ERC20Token} from "../src/ERC20Token.sol";
import {NFTToken} from "../src/NFTToken.sol";

contract NFTMarketScript is Script {
    NFTMarket public nftMarket;
    ERC20Token public erc20Token;
    NFTToken public nftToken;

    function setUp() public {}

    function run() external {
        vm.startBroadcast();
        nftMarket = new NFTMarket();
        erc20Token = new ERC20Token();
        nftToken = new NFTToken();
        vm.stopBroadcast();
    }
}
