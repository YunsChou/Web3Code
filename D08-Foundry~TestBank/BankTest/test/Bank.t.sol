// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;

    function setUp() public {
        console.log("-->> BankTest setUp");

        bank = new Bank();
    }

    function test_depositETH() external payable {
        address alice = address(1);
        vm.deal(alice, 10 ether);

        console.log("-->> test_depositETH");
        vm.startPrank(alice);
        // 调用合约存款
        uint256 amount = 2 ether;
        // 检查事件(先触发事件)
        vm.expectEmit(true, true, false, false);
        emit Bank.Deposit(alice, amount);
        // 检查用户余额
        uint256 before_banlance = bank.balanceOf(alice);
        console.log("-->> before_banlance: ", before_banlance);
        // 调用存款
        (bool succ,) = address(bank).call{value: amount}(abi.encodeWithSignature("depositETH()"));
        require(succ, "call depositETH fail");
        // bank.depositETH{value: amount}(); // 也可以用这种方式调用

        // 检查用户余额
        uint256 after_banlance = bank.balanceOf(alice);
        console.log("-->> after_banlance: ", after_banlance);
        assertEq(after_banlance, amount, "value should match");

        vm.stopPrank();
    }
}
