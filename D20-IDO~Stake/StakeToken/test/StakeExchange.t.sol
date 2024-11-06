// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "../src/StakeExchange.sol";
import "../src/esRNTToken.sol";

contract StakeExchangeTest is Test {
    MockERC20 public mockToken;
    esRNTToken public profitToken;
    StakeExchange public exchange;
    address public alice;

    function setUp() public {
        mockToken = deployMockERC20("RNToken", "RNT", 18);
        profitToken = new esRNTToken();
        exchange = new StakeExchange(address(mockToken));
        alice = makeAddr("alice");

        deal(address(mockToken), address(exchange), 1000000);

        deal(address(profitToken), alice, 1000);
        console.log("-->> profitToken.balanceOf(alice): ", profitToken.balanceOf(alice));
        vm.prank(alice);
        profitToken.approve(address(exchange), type(uint256).max);
    }

    function test_createExchangeOrder() external {
        // vm.startPrank(alice);
        exchange.createExchangeOrder(alice, 100);

        exchange.createExchangeOrder(alice, 300);
        // vm.stopPrank();

        (,,, uint256 exchangeNumber,) = exchange.exchanges(alice, 0);
        console.log("-->> exchanges: ", exchangeNumber);

        (,,, uint256 exchangeNumber2,) = exchange.exchanges(alice, 1);
        console.log("-->> exchanges2: ", exchangeNumber2);

        assertEq(exchangeNumber, 100, "exchangeNumber is error");
        assertEq(exchangeNumber2, 300, "exchangeNumber2 is error");
    }

    function test_exchangeToRNT() external {
        console.log("-->> profitToken.balanceOf(alice)1: ", profitToken.balanceOf(alice));

        vm.startPrank(alice);
        exchange.createExchangeOrder(alice, 100);
        // exchange.createExchangeOrder(200);

        vm.warp(block.timestamp + 31 days);
        uint8[] memory exchangeIds = new uint8[](1);
        exchangeIds[0] = 0;
        exchange.exchangeToRNT(exchangeIds);
        vm.stopPrank();

        // 验证：兑换数量
        (,,, uint256 exchangeNumber, uint256 hadExchangedNumber) = exchange.exchanges(alice, 0);
        console.log("-->> exchanges: ", exchangeNumber);
        console.log("-->> hadExchangedNumber: ", hadExchangedNumber);
        assertEq(exchangeNumber, 0, "exchangeNumber is error");
        assertEq(hadExchangedNumber, 100, "hadExchangedNumber is error");

        // 验证：余额
        console.log("-->> profitToken.balanceOf(alice)2: ", profitToken.balanceOf(alice));
        assertEq(mockToken.balanceOf(alice), 100, "balance is error");
        assertEq(profitToken.balanceOf(alice), 900, "balance is error");
    }

    function test_checkExchangeRNTAmount() public {
        ExchangeInfoStruct memory exchangeInfo = ExchangeInfoStruct({
            isExchanged: false,
            exchangeStartTime: block.timestamp,
            exchangeFinishTime: 0,
            exchangeNumber: 30,
            hadExchangedNumber: 0
        });

        // 模拟时间
        vm.warp(block.timestamp + 31 days);

        uint256 RNTs = exchange.checkExchangeRNTAmount(exchangeInfo);

        // 验证：可兑换的rnt数量
        assertEq(RNTs, 30 * 30 / 30, "can exchange rnts error");
    }
}
