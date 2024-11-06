// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/IDORaise.sol";

contract IDORaiseTest is Test {
    IDORaise public ido;

    function setUp() public {
        ido = new IDORaise();
    }
}
