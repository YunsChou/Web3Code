// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./esRNToken.sol";

import {console} from "forge-std/Test.sol";

struct StakeInfoStruct {
    uint256 stakeNumber;
    uint256 stakeStartTime;
    uint256 unClaimNumber;
}

contract StakePool {
    address public stakeToken;
    esRNToken public profitToken;

    uint256 public profitRatePerday; // 1 esRNT/day

    mapping(address => StakeInfoStruct) public stakeInfos;

    constructor(address _stakeToken, address _profitToken, uint256 _profitRatePerday) {
        stakeToken = _stakeToken;
        profitToken = esRNToken(_profitToken);
        profitRatePerday = _profitRatePerday;
    }

    modifier hadStaked() {
        StakeInfoStruct memory stakeInfo = stakeInfos[msg.sender];
        require(stakeInfo.stakeNumber > 0, "not stake");
        _;
    }

    // 质押
    function stake(uint256 amount) external {
        console.log("-->> time-stake:", block.timestamp);
        require(IERC20(stakeToken).allowance(msg.sender, address(this)) >= amount, "allowance is less stake amount");
        require(IERC20(stakeToken).balanceOf(msg.sender) >= amount, "balance is less stake amount");
        // user将质押的RNT转入StakePool合约
        IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
        // 更新质押收益
        updatestakingIncome(msg.sender);
        // StakeInfoStruct memory stakeInfo = stakeInfos[msg.sender];
        // stakeInfo.stakeNumber += amount; // 质押RNT累加

        stakeInfos[msg.sender].stakeNumber += amount;
    }

    // 解除质押
    function unstake(uint256 amount) external hadStaked {
        // StakeInfoStruct memory stakeInfo = stakeInfos[msg.sender];
        require(stakeInfos[msg.sender].stakeNumber >= amount, "stakeNumber is not enougth");

        stakeInfos[msg.sender].stakeNumber -= amount;
        // 将StakePool的RNT转给user
        IERC20(stakeToken).transfer(msg.sender, amount);
    }

    function claimTokens() external {
        updatestakingIncome(msg.sender);
        uint256 unClaimNum = stakeInfos[msg.sender].unClaimNumber;
        require(unClaimNum > 0, "unClaimNumber is 0");
        console.log("-->> claimTokens unClaimNum:", unClaimNum);
        stakeInfos[msg.sender].unClaimNumber = 0;
        // 将收益代币esRNT分发给user
        profitToken.mint(msg.sender, unClaimNum);
    }

    // 计算收益（未领取的质押数量，当前质押的收益）
    function updatestakingIncome(address account) public returns (uint256 unClaimNum) {
        StakeInfoStruct memory stakeInfo = stakeInfos[account];
        if (stakeInfo.stakeStartTime > 0) {
            uint256 stakeTime = block.timestamp - stakeInfo.stakeStartTime;

            stakeInfo.unClaimNumber += (stakeInfo.stakeNumber * stakeTime * profitRatePerday) / 1 days;
            unClaimNum = stakeInfo.unClaimNumber;
        }
        stakeInfo.stakeStartTime = block.timestamp;

        stakeInfos[account] = stakeInfo;
    }

    // 查询质押信息
    // 外部为什么无法访问publicstakeInfos？答：结构体的可见性：StakeInfoStruct
    function checkStakePools(address account) external returns (StakeInfoStruct memory) {
        updatestakingIncome(account);
        StakeInfoStruct memory stakeInfo = stakeInfos[account];
        return stakeInfo;
    }
}

/**
 * 要求：esRNT代币要发到用户手上，锁仓(记录锁仓时间，和兑换RNT比例相关)，用户要可兑换RNT
 * 与用户的交互：质押RNT挖矿esRNT，esRNT仅用于兑换RNT
 * 0、项目方分配挖矿esRNT可兑换代币RNT数 --> 分配RNT到esRNT合约
 * 1、用户质押【在StakePool上执行】； --> 可追加，可提取（部份）
 * 2、用户点领取【在StakePool上执行】；--> esRNT 到用户 EOA账户；同时在esRNT合约上 记录一个【兑换订单】(产生时间)
 * 3、用户点兑换【在esRNT上执行】。--> 用户在合约上点【兑换订单】，根据时长条件，消耗esRNT生成对应比例的RNT
 *
 *  问题：esRNT是从哪里来的，如何到用户手上？
 *  esRNT只有部署的owner才能mint，在StakePool中调用esRNT.mint会报错；
 *  给esRNT合约增加admins，admin可以mint（将stakePool合约地址添加到admins）；
 *
 *  问题：esRNT上兑换的额RNT是哪里来的？
 *  可以项目方通过mint，也可以项目方通过transfer，分配RNT到esRNT合约；
 *
 *  问题：还有没有其他的设计方式？
 */
