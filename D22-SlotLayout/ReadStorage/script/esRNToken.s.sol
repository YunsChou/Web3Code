// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {esRNToken} from "../src/esRNToken.sol";

contract esRNTokenScript is Script {
    esRNToken public token;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        token = new esRNToken();

        vm.stopBroadcast();
    }
}
