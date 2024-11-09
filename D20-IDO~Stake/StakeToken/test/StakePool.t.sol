// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "../src/StakePool.sol";
import "../src/esRNToken.sol";

contract StakePoolTest is Test {
    StakePool public pool;
    MockERC20 public mockToken;
    esRNToken public profitToken;
    address public alice;

    uint256 constant totalToken = 100000 * 1e18;
    uint256 constant approveToken = 500 * 1e18;

    uint256 constant profit_day = 1 * 1e18; // 质押一个RNT，每小时1个esRNT

    function setUp() public {
        mockToken = deployMockERC20("RNToken", "RNT", 18);
        profitToken = new esRNToken();
        uint256 profitRatePerday = 1; // 1 RNT/esRNT/day
        pool = new StakePool(address(mockToken), address(profitToken), profitRatePerday);

        profitToken.initialize(address(mockToken));
        alice = makeAddr("alice");

        profitToken.addAdmin(address(pool), true); // 给pool添加铸币权限
        console.log("profitToken.Admin():", address(pool));

        deal(address(mockToken), alice, totalToken); // 给alice打币

        vm.prank(alice);
        mockToken.approve(address(pool), approveToken); // 给pool授权
    }

    function test_stake() public {
        uint256 stakeAmount1 = 100 * 1e18;
        uint256 stakeAmount2 = 200 * 1e18;

        vm.startPrank(alice);

        // 第一笔质押
        pool.stake(stakeAmount1);
        assertEq(mockToken.balanceOf(alice), totalToken - stakeAmount1, "alice balance1 is error");
        StakeInfoStruct memory stakeInfo1 = pool.checkStakePools(alice);
        assertEq(stakeInfo1.stakeNumber, stakeAmount1, "stakeNumber1 is error");
        assertEq(stakeInfo1.unClaimNumber, 0, "unClaimNumber1 is error");

        // 模拟时间
        vm.warp(block.timestamp + 3 days);
        uint256 incoming1 = pool.updatestakingIncome(alice);
        console.log("-->> incoming1: ", incoming1);
        // 第二笔质押
        pool.stake(stakeAmount2);

        // 模拟时间
        vm.warp(block.timestamp + 5 days);
        uint256 incoming2 = pool.updatestakingIncome(alice);
        console.log("-->> incoming2: ", incoming2);

        assertEq(mockToken.balanceOf(alice), totalToken - stakeAmount1 - stakeAmount2, "alice balance2 is error");
        StakeInfoStruct memory stakeInfo2 = pool.checkStakePools(alice);
        assertEq(stakeInfo2.stakeNumber, stakeAmount1 + stakeAmount2, "stakeNumber2 is error");

        vm.stopPrank();
    }

    function mockStakeAction() public {
        uint256 stakeAmount1 = 100 * 1e18;
        uint256 stakeAmount2 = 200 * 1e18;

        // 第一笔质押
        pool.stake(stakeAmount1);
        // 模拟时间
        vm.warp(block.timestamp + 3 days);
        // 第二笔质押
        pool.stake(stakeAmount2);
    }

    function test_claimTokens() external {
        vm.startPrank(alice);
        mockStakeAction();
        // 模拟时间
        vm.warp(block.timestamp + 2 days);

        uint256 incoming2 = pool.updatestakingIncome(alice);
        console.log("-->> incoming2: ", incoming2);
        // 领取esRNT
        pool.claimTokens();
        vm.stopPrank();

        // 验证alice: 待领取esRNT为0，帐户领取esRNT
        StakeInfoStruct memory stakeInfo = pool.checkStakePools(alice);
        assertEq(stakeInfo.unClaimNumber, 0, "unClaimNumber is error");
        assertEq(profitToken.balanceOf(alice), 3 * profit_day * 100 + 2 * profit_day * 300, "profit token is error");
    }

    function test_unStake() external {
        vm.startPrank(alice);
        mockStakeAction();
        // 模拟时间
        vm.warp(block.timestamp + 2 days);
        // 解除质押，并领取esRNT
        pool.unstake(120 * 1e18);
        vm.stopPrank();

        // 验证alice在pool质押的RNT代币
        StakeInfoStruct memory stakeInfo = pool.checkStakePools(alice);
        assertEq(stakeInfo.stakeNumber, 180 * 1e18, "stakeNumber is error");
    }

    function test_updatestakingIncome() public {
        vm.startPrank(alice);

        mockStakeAction();

        vm.warp(block.timestamp + 2 days);

        // 验证alice的待领取esRNT
        StakeInfoStruct memory stakeInfo = pool.checkStakePools(alice);
        assertEq(stakeInfo.unClaimNumber, 3 * profit_day * 100 + 2 * profit_day * 300, "unClaimNumber is error");

        vm.stopPrank();
    }
}
