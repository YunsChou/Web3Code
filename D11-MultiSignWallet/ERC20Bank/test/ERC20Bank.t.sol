// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/Test.sol";
import "../src/ERC20Bank.sol";

contract ERC20BankTest is Test {
    ERC20Bank public bank;
    address public owner;
    address public alice;

    // 在每个测试用例前设置测试环境
    function setUp() public {
        owner = address(this);
        alice = makeAddr("alice");
        bank = new ERC20Bank();
    }

    // 测试初始化状态
    function testInitialState() public view {
        assertEq(bank._owner(), address(this));
        assertEq(bank.getBankBalance(), 0);
    }

    // 测试管理员更改功能
    function testChangeAdmin() public {
        bank.changeAdmin(alice);
        assertEq(bank._owner(), alice);
    }

    // 测试非管理员无法更改管理员
    function testFailNonOwnerChangeAdmin() public {
        vm.prank(alice);
        bank.changeAdmin(alice);
    }

    // 测试提款功能
    function testWithdrawToAdmin() public {
        // 首先存入一些ETH
        uint256 depositAmount = 1 ether;
        payable(address(bank)).transfer(depositAmount);

        // 记录提款前的余额
        uint256 ownerBalanceBefore = address(this).balance;

        // 执行提款
        bank.withdrawToAdmin();

        // 验证提款后的状态
        assertEq(bank.getBankBalance(), 0);
        assertEq(address(this).balance, ownerBalanceBefore + depositAmount);
    }

    // 测试空余额时无法提款
    function testFailWithdrawWithZeroBalance() public {
        bank.withdrawToAdmin();
    }

    // 用于接收ETH的回退函数
    receive() external payable {}
}
