// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Test.sol";
import "../src/RNToken.sol";
import "../src/esRNToken.sol";

contract esRNTokenTest is Test {
    RNToken public rnt;
    esRNToken public esRNT;
    address public admin1;
    address public user;
    uint256 public constant USER_RNT_AMOUNT = 300 * 1e18;

    function setUp() public {
        rnt = new RNToken();
        esRNT = new esRNToken();
        admin1 = address(0x2);
        user = address(0x3);

        esRNT.initialize(address(rnt));
        esRNT.addAdmin(admin1, true);

        // 给esRNT转1000个RNT
        rnt.mint(address(esRNT), 1000 * 1e18);

        // 给用户转1000个RNT
        rnt.mint(user, USER_RNT_AMOUNT);
    }

    function test_balanceOf() public view {
        assertEq(rnt.balanceOf(user), USER_RNT_AMOUNT);
        assertEq(rnt.balanceOf(address(esRNT)), 1000 * 1e18);
    }

    function test_mint() public {
        uint256 claimAmount = 100 * 1e18;
        // 模拟claimTokens
        vm.prank(admin1);
        esRNT.mint(user, claimAmount);
        assertEq(esRNT.balanceOf(user), claimAmount);

        // 检查lockInfos是否正确
        // LockInfo[] memory lockInfos = esRNT.lockInfos(user); // 确保lockInfos的返回值正确
        LockInfo[] memory lockInfos = esRNT.checkLockList(user);
        assertEq(lockInfos.length, 1);
        assertEq(lockInfos[0].amount, claimAmount);
    }

    function test_convertToRNT() external {
        uint256 claimAmount = 100 * 1e18;
        // 模拟claimTokens
        vm.prank(admin1);
        esRNT.mint(user, claimAmount);

        // 等待30天
        vm.warp(block.timestamp + 30 days);

        // 选择下标
        uint8[] memory indexs = new uint8[](1);
        indexs[0] = 0;

        // 模拟convertToRNT
        vm.prank(user);
        esRNT.convertToRNT(indexs);

        // 检查余额
        assertEq(esRNT.balanceOf(user), 0);
        assertEq(rnt.balanceOf(user), claimAmount + USER_RNT_AMOUNT);
    }

    function test_calcConvertRNTAmount() external {
        uint256 claimAmount1 = 80 * 1e18;
        // 模拟claimTokens
        vm.prank(admin1);
        esRNT.mint(user, claimAmount1);

        // 3天后质押第二笔
        vm.warp(block.timestamp + 3 days);
        uint256 claimAmount2 = 50 * 1e18;
        vm.prank(admin1);
        esRNT.mint(user, claimAmount2);

        // 检查esRNT的余额
        assertEq(esRNT.balanceOf(user), claimAmount1 + claimAmount2);

        // 等待20天
        vm.warp(block.timestamp + 20 days);
        // 选择下标
        uint8[] memory indexs = new uint8[](2);
        indexs[0] = 0;
        indexs[1] = 1;

        // 计算可兑换的RNT
        uint256 convertRNTAmount1 = esRNT.calcConvertRNTAmount(esRNT.checkLockList(user)[0]);
        uint256 convertRNTAmount2 = esRNT.calcConvertRNTAmount(esRNT.checkLockList(user)[1]);
        console.log("convertRNTAmount1", convertRNTAmount1);
        console.log("convertRNTAmount2", convertRNTAmount2);

        // 模拟convertToRNT
        vm.prank(user);
        esRNT.convertToRNT(indexs);

        // 检查余额
        assertEq(esRNT.balanceOf(user), 0);
        assertEq(rnt.balanceOf(user), convertRNTAmount1 + convertRNTAmount2 + USER_RNT_AMOUNT);
    }
}
