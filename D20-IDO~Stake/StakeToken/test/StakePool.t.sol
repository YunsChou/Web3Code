// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "../src/StakePool.sol";

contract StakePoolTest is Test {
    StakePool public pool;
    MockERC20 public mockToken;
    address public alice;

    uint256 constant totalToken = 100000;
    uint256 constant approveToken = 500;

    uint256 constant profit_day = 24 * 3600; // 质押一个RNT，每小时36个esRNT

    function setUp() public {
        mockToken = deployMockERC20("RNToken", "RNT", 18);
        pool = new StakePool(address(mockToken), profit_day);
        alice = makeAddr("alice");

        deal(address(mockToken), alice, totalToken);

        vm.prank(alice);
        mockToken.approve(address(pool), approveToken);
    }

    function test_stake() external {
        uint256 stakeAmount1 = 100;
        uint256 stakeAmount2 = 200;

        vm.startPrank(alice);

        // 第一笔质押
        pool.stake(stakeAmount1);

        assertEq(mockToken.balanceOf(alice), totalToken - stakeAmount1, "alice balance1 is error");
        (uint256 stakeNumber1, uint256 stakeStartTime1, uint256 unClaimNumber1) = pool.stakePools(alice);
        assertEq(stakeNumber1, stakeAmount1, "stakeNumber1 is error");
        assertEq(unClaimNumber1, 0, "unClaimNumber1 is error");

        console.log("-->> time1:", block.timestamp);
        StakeInfoStruct memory stakeInfo = StakeInfoStruct(stakeNumber1, stakeStartTime1, unClaimNumber1);

        // 模拟时间
        vm.warp(block.timestamp + 3 days);
        console.log("-->> time2:", block.timestamp);
        console.log("-->> stakeStartTime: ", stakeInfo.stakeStartTime);
        uint256 incoming = pool.stakingIncome(stakeInfo);
        console.log("-->> incoming: ", incoming);
        // 第二笔质押
        pool.stake(stakeAmount2);

        assertEq(mockToken.balanceOf(alice), totalToken - stakeAmount1 - stakeAmount2, "alice balance2 is error");
        (uint256 stakeNumber2,, uint256 unClaimNumber2) = pool.stakePools(alice);
        console.log("-->> unClaimNumber2: ", unClaimNumber2);
        assertEq(stakeNumber2, stakeAmount1 + stakeAmount2, "stakeNumber2 is error");
        assertEq(unClaimNumber2, 3 * profit_day * stakeAmount1, "unClaimNumber2 is error");

        vm.stopPrank();
    }

    function mockStakeAction() public {
        uint256 stakeAmount1 = 100;
        uint256 stakeAmount2 = 200;

        // 第一笔质押
        pool.stake(stakeAmount1);
        // 模拟时间
        vm.warp(block.timestamp + 3 days);
        // 第二笔质押
        pool.stake(stakeAmount2);
    }

    function test_onlyClaimTokens() external {
        vm.startPrank(alice);
        mockStakeAction();
        // 模拟时间
        vm.warp(block.timestamp + 2 days);
        // 领取esRNT
        pool.onlyClaimTokens();
        vm.stopPrank();

        // 验证质押：RNT代币没减少，待领取esRNT为0
        (uint256 stakeNumber1,, uint256 unClaimNumber1) = pool.stakePools(alice);
        assertEq(stakeNumber1, 300, "stakeNumber is error");
        assertEq(unClaimNumber1, 0, "unClaimNumber1 is error");
        // 验证alice：RNT代币-300，esRNT领取到账户
        assertEq(mockToken.balanceOf(alice), totalToken - 300, "alice balance is error");
        assertEq(
            IERC20(pool.profitToken()).balanceOf(alice),
            3 * profit_day * 100 + 2 * profit_day * 300,
            "profit token is error"
        );
    }

    function test_unState() external {
        vm.startPrank(alice);
        mockStakeAction();
        // 模拟时间
        vm.warp(block.timestamp + 2 days);
        // 解除质押，并领取esRNT
        pool.unState();
        vm.stopPrank();

        // 验证质押：RNT代币为0，待领取esRNT为0
        (uint256 stakeNumber1,, uint256 unClaimNumber1) = pool.stakePools(alice);
        assertEq(stakeNumber1, 0, "stakeNumber is error");
        assertEq(unClaimNumber1, 0, "unClaimNumber1 is error");
        // 验证alice：RNT代币没变，esRNT领取到账户
        assertEq(mockToken.balanceOf(alice), totalToken, "alice balance is error");
        assertEq(
            IERC20(pool.profitToken()).balanceOf(alice),
            3 * profit_day * 100 + 2 * profit_day * 300,
            "profit token is error"
        );
    }

    function test_stakingIncome() public {
        uint256 stakeAmount = 100;

        vm.startPrank(alice);
        // 执行质押
        pool.stake(stakeAmount);
        (uint256 stakeNumber, uint256 stakeStartTime, uint256 unClaimNumber) = pool.stakePools(alice);
        StakeInfoStruct memory stakeInfo = StakeInfoStruct(stakeNumber, stakeStartTime, unClaimNumber);

        // 模拟时间
        vm.warp(block.timestamp + 2 days);
        uint256 incoming = pool.stakingIncome(stakeInfo);
        assertEq(incoming, 2 * profit_day * stakeAmount, "profit is error");

        vm.stopPrank();
    }
}
