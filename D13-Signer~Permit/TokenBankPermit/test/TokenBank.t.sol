// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/TokenBank.sol";
import "../src/PermitToken.sol";

contract TokenBankTest is Test {
    uint256 public initTokenAmount = 10000 * 10 ** 18;

    PermitToken public token;
    TokenBank public bank;

    address public owner;
    uint256 public privateKey = 0x123;

    function setUp() public {
        token = new PermitToken();
        bank = new TokenBank(token);
        vm.label(owner, "bank");

        // 设置私钥生成用户
        owner = vm.addr(privateKey);
        vm.label(owner, "user");
        token.mint(owner, initTokenAmount);
    }

    function test_tokenAmount() external view {
        assertEq(token.totalSupply(), initTokenAmount, "totalSupply is error");
    }

    function test_deposit() external payable {
        uint256 depositValue = 20 * 10 ** 18;
        _approveAndDeposit(depositValue);

        assertEq(token.balanceOf(address(bank)), depositValue, "bank balance error");
        assertEq(bank.addressAmount(owner), depositValue, "deposit value error");
    }

    // 提现
    function test_withdraw() external payable {
        uint256 depositValue = 20 * 10 ** 18;
        _approveAndDeposit(depositValue);

        vm.prank(owner);
        // 提现
        bank.withdraw(depositValue);
        console.log("-->> bank.addressAmount2: ", bank.addressAmount(owner));

        assertEq(token.balanceOf(address(bank)), 0, "bank balance error");
        assertEq(bank.addressAmount(owner), 0, "withdraw value error");
    }

    function testFail_withdraw() external payable {
        uint256 depositValue = 20 * 10 ** 18;
        _approveAndDeposit(depositValue);
        vm.prank(owner);
        bank.withdraw(depositValue + 1);
    }

    function _approveAndDeposit(uint256 amount) internal {
        vm.startPrank(owner);
        token.approve(address(bank), amount);
        bank.deposit(amount);
        vm.stopPrank();
    }

    function test_permitDeposit() external payable {
        uint256 spendValue = 20 * 10 ** 18;
        uint256 deadline = block.timestamp + 3 hours;

        // 用户
        vm.startPrank(owner);
        // -- token
        // 以太坊签名消息
        bytes32 msgHash = token.getPermitDigest(owner, address(bank), spendValue, deadline);
        // 使用私钥签名, 获取 rsv
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        // -- bank
        // vm.startPrank(address(bank));
        bank.permitDeposit(owner, address(bank), spendValue, deadline, v, r, s);
        // 检查结果
        console.log("-->> bank.addressAmount: ", bank.addressAmount(owner));
        assertEq(bank.addressAmount(owner), spendValue, "permit trans value error");
        assertEq(token.balanceOf(address(bank)), spendValue, "bank balance error");
        // vm.stopPrank();

        vm.stopPrank();
    }
}
