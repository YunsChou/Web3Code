// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {esRNToken} from "../src/esRNToken.sol";

contract esRNTokenScript is Script {
    esRNToken public esRNT;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        esRNT = new esRNToken();

        vm.stopBroadcast();
    }
}
