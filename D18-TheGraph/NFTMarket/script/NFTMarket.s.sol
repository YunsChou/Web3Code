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

/**
##### sepolia
✅  [Success]Hash: 0x5f5ea2698eaec49a565921404862ebbd55ec2f7a9b93b00059e768e8d7e460e8
Contract Address: 0xeBd742647f4B1b20B18A0D949F853Beb98A2Df18
Block: 6975540
Paid: 0.007402582478244914 ETH (571822 gas * 12.945606287 gwei)


##### sepolia
✅  [Success]Hash: 0xda05e02f7c65625e6ec9402f5199e326df5c56ea017908dceeec52dcec22393e
Contract Address: 0x19E6C5aeCD7cD1E7236F6803C01ACfe0250ae6F9
Block: 6975540
Paid: 0.007979606987275365 ETH (616395 gas * 12.945606287 gwei)


##### sepolia
✅  [Success]Hash: 0x9694de422efc1476d93e8427679c3e2184db22d0b20159ed3939488160253f5f
Contract Address: 0xd5bF6485A2Dad3bd56DBa87DF6f869d14bc2647A
Block: 6975540
Paid: 0.015889527775907809 ETH (1227407 gas * 12.945606287 gwei)
 */