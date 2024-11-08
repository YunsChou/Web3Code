// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/IDORaise.sol";
import "../src/RNTToken.sol";

contract IDORaiseTest is Test {
    RNTToken public rnt;
    IDORaise public ido;

    address admin = makeAddr("admin");
    address alice = makeAddr("alice");
    address bob = makeAddr("bob");

    uint256 constant alice_eths = 1 ether;
    uint256 constant bob_eths = 2 ether;

    function setUp() public {
        vm.startPrank(admin);
        rnt = new RNTToken();
        ido = new IDORaise(address(rnt));

        vm.stopPrank();

        deal(address(rnt), address(ido), 1000000 * 1e18);
        deal(alice, alice_eths);
        deal(bob, bob_eths);
    }

    function test_preSale() public {
        // 调用 call 转入
        vm.prank(alice);
        (bool success,) = address(ido).call{value: 0.01 ether}("");
        assertTrue(success);

        // 调用 preSale 转入
        vm.prank(bob);
        ido.preSale{value: 0.05 ether}();

        // 检查合约余额
        assertEq(ido.totalETH(), 0.06 ether);
        // 检查合约用户募集金额
        assertEq(ido.balances(bob), 0.05 ether);

        // 检查用户余额
        assertEq(address(bob).balance, 1.95 ether);
    }

    function testFail_preSale() external {
        // 存入 < 0.01 ether
        vm.prank(alice);
        (bool success,) = address(ido).call{value: 0.009 ether}("");
        assertTrue(success);

        // 存入 > 0.1 ether
        vm.prank(bob);
        vm.expectRevert();
        ido.preSale{value: 0.11 ether}();
    }

    function test_raiseFinish() external {
        vm.warp(ido.endTime() + 1);
        vm.roll(block.number + 1);
        vm.prank(admin);
        ido.raiseFinish();

        assertEq(ido.isEnd(), true);
    }

    function test_claim() external {
        // 先让用户投资足够的 ETH (至少 100 ether)
        for (uint160 i = 1; i <= 1000; i++) {
            address user = address(i);
            vm.deal(user, 0.1 ether);
            vm.prank(user);
            ido.preSale{value: 0.1 ether}();
        }
        console.log(ido.totalETH());
        // alice 投资 0.05 ether
        uint256 eths = 0.05 ether;
        vm.prank(alice);
        ido.preSale{value: eths}();
        console.log(ido.totalETH());

        // 结束募集
        vm.warp(ido.endTime() + 1);
        vm.roll(block.number + 1);
        vm.prank(admin);
        ido.raiseFinish();

        // 用户领取
        vm.prank(alice);
        ido.claim();

        // 检查用户领取后余额
        assertEq(ido.balances(alice), 0);
        console.log(rnt.balanceOf(alice));
        console.log(ido.realClaimAmount(eths));
        assertEq(rnt.balanceOf(alice), ido.realClaimAmount(eths));

        // 检查合约rnt余额
        assertEq(rnt.balanceOf(address(ido)), 1000000 * 1e18 - rnt.balanceOf(alice));
    }

    function test_refund() external {
        // 用户投资 0.05 ether
        uint256 eths = 0.05 ether;
        vm.prank(alice);
        ido.preSale{value: eths}();

        // 检查用户余额
        assertEq(ido.balances(alice), eths);
        assertEq(address(alice).balance, alice_eths - eths);

        // 结束募集
        vm.warp(ido.endTime() + 1);
        vm.roll(block.number + 1);
        vm.prank(admin);
        ido.raiseFinish();

        // 检查用户退款
        vm.prank(alice);
        ido.refund();
        assertEq(ido.balances(alice), 0);
        assertEq(address(alice).balance, alice_eths);
    }

    function test_withdraw() external {
        // 模拟募集
        for (uint160 i = 1; i <= 1000; i++) {
            address user = address(i);
            vm.deal(user, 0.1 ether);
            vm.prank(user);
            ido.preSale{value: 0.1 ether}();
        }

        // alice 投资 0.05 ether
        uint256 eths = 0.05 ether;
        vm.prank(alice);
        ido.preSale{value: eths}();

        // 结束募集
        vm.warp(ido.endTime() + 1);
        vm.roll(block.number + 1);
        vm.prank(admin);
        ido.raiseFinish();

        // 项目方提取
        vm.prank(admin);
        ido.withdraw();

        // 检查合约eth余额
        assertEq(address(ido).balance, 0);

        // 检查项目方eth余额
        assertEq(address(admin).balance, 100.05 ether);
    }

    function test_checkIsEnd() external {
        // 募集时间结束，isEnd 为 true
        vm.warp(ido.endTime() + 1);
        vm.roll(block.number + 1);

        console.log(ido.endTime());
        console.log(block.timestamp + 1);

        assertEq(ido.checkIsEnd(), true);
    }
}
