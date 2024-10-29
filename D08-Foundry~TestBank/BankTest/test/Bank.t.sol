// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {Bank} from "../src/Bank.sol";

contract BankTest is Test {
    Bank public bank;
    address public alice = address(1);
    address public bob = address(2);

    function setUp() public {
        console.log("-->> BankTest setUp");

        bank = new Bank();
        vm.deal(alice, 10 ether);
        vm.deal(bob, 10 ether);
    }

    function test_depositETH() external payable {
        console.log("-->> test_depositETH");
        vm.startPrank(alice);
        // 调用合约存款
        uint256 amount = 2 ether;
        // 检查事件(先标记触发事件)
        vm.expectEmit(true, false, false, true);
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

    function test_depositZeroAmount() external {
        vm.startPrank(alice);
        vm.expectRevert("Deposit amount must be greater than 0");
        bank.depositETH{value: 0}();
        vm.stopPrank();
    }

    function test_depositMultAmount() external {
        vm.startPrank(alice);
        bank.depositETH{value: 1 ether}();
        bank.depositETH{value: 2 ether}();

        assertEq(bank.balanceOf(alice), 3 ether, "mult amount is error");

        vm.stopPrank();
    }

    function test_depositMultUser() external {
        vm.prank(alice);
        bank.depositETH{value: 5 ether}();

        vm.prank(bob);
        bank.depositETH{value: 2 ether}();

        assertEq(bank.balanceOf(alice), 5 ether, "alice balance is error");
        assertEq(bank.balanceOf(bob), 2 ether, "bob balance is error");
    }

    function test_depositMoreThanBanlance() external {
        vm.prank(alice);
        vm.expectRevert();
        bank.depositETH{value: 11 ether}();
    }

    function test_depositContractBalance() external {
        vm.prank(bob);
        bank.depositETH{value: 2 ether}();

        uint256 initAmount = address(bank).balance;
        uint256 depositAmount = 3 ether;
        vm.prank(alice);
        bank.depositETH{value: depositAmount}();

        assertEq(address(bank).balance, initAmount + depositAmount, "balance is error");
    }
}
