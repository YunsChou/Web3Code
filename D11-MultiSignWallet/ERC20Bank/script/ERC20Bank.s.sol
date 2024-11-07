// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {ERC20Bank} from "../src/ERC20Bank.sol";

contract ERC20BankScript is Script {
    ERC20Bank public bank;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        bank = new ERC20Bank();

        vm.stopBroadcast();
    }
}
