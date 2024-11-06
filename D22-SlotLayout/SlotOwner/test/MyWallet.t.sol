// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MyWallet} from "../src/MyWallet.sol";

contract MyWalletTest is Test {
    MyWallet public wallet;
    address public alice;

    bytes32 private constant MyWalletLoction = keccak256("1");

    function setUp() public {
        wallet = new MyWallet("YYWallet");
        alice = makeAddr("alice");
    }

    function test_getStorageSlotOwner() public view {
        address addr = wallet.getStorageSlotOwner();
        assertEq(address(this), addr, "addr not owner");
    }

    function test_setStorageSlotOwner() public {
        wallet.setStorageSlotOwner(alice);

        address addr = wallet.getStorageSlotOwner();
        assertEq(alice, addr, "addr not owner");
    }
}
