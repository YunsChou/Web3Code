// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {esRNToken} from "../src/esRNToken.sol";

contract esRNTokenTest is Test {
    esRNToken public token;

    function setUp() public {
        token = new esRNToken();
    }

    function test_getLocks() external view {
        esRNToken.LockInfo[] memory locks = token.getLocks();
        // 打印数组长度
        console.log("Array length:", locks.length);

        // 打印数组内容
        for (uint256 i = 0; i < locks.length; i++) {
            console.log("numbers[%s]: %s", i, locks[i].user);
        }
    }
}
