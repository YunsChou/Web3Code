// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./esRNTToken.sol";
import "./StakeExchange.sol";

import {console} from "forge-std/Test.sol";

struct StakeInfoStruct {
    uint256 stakeNumber;
    uint256 stakeStartTime;
    uint256 unClaimNumber;
}

contract StakePool {
    address public stakeToken;
    esRNTToken public profitToken;
    StakeExchange public stateExchange;

    uint256 public profitPerday;
    uint256 public profitPerSeconds;

    mapping(address => StakeInfoStruct) public stakePools;

    constructor(address _stakeToken, uint256 _profitPerday) {
        stakeToken = _stakeToken;
        profitToken = new esRNTToken();
        stateExchange = new StakeExchange(stakeToken);
        profitPerday = _profitPerday;
        profitPerSeconds = profitPerday / (24 * 60 * 60); // 这里相除结果为小数强转为整数后，结果为0
    }

    // 质押
    function stake(uint256 amount) external {
        console.log("-->> time-stake:", block.timestamp);
        require(IERC20(stakeToken).allowance(msg.sender, address(this)) >= amount, "allowance is less stake amount");
        require(IERC20(stakeToken).balanceOf(msg.sender) >= amount, "balance is less stake amount");
        IERC20(stakeToken).transferFrom(msg.sender, address(this), amount);
        // 判断是否已有质押
        StakeInfoStruct memory stakeInfo = stakePools[msg.sender];
        if (stakeInfo.stakeNumber > 0) {
            // 有正在质押的单子【更新质押】
            console.log("-->> stakingIncome: ", stakingIncome(stakeInfo));
            stakeInfo.unClaimNumber += stakingIncome(stakeInfo); // 将实时收益换算到待领取的esRNT
            stakeInfo.stakeNumber += amount; // 质押RNT累加
            stakeInfo.stakeStartTime = block.timestamp;
        } else {
            // 没有正在质押的单子
            stakeInfo = StakeInfoStruct({stakeNumber: amount, stakeStartTime: block.timestamp, unClaimNumber: 0});
        }

        stakePools[msg.sender] = stakeInfo;
    }

    // 领取质押代币
    function onlyClaimTokens() external hadStaked {
        claimWithUnStake(false);
    }

    // 质押赎回：
    function unState() external hadStaked {
        claimWithUnStake(true);
    }

    function claimWithUnStake(bool isUnState) public {
        StakeInfoStruct memory stakeInfo = stakePools[msg.sender];

        // 计算收益
        uint256 tokenAmount = stakeInfo.unClaimNumber + stakingIncome(stakeInfo);
        // 提取收益代币到用户账户，并生成一个兑换订单
        profitToken.mint(msg.sender, tokenAmount);
        stateExchange.createExchangeOrder(msg.sender, tokenAmount);

        if (isUnState) {
            // 清除该用户质押
            // 提取质押代币到用户账户
            IERC20(stakeToken).transfer(msg.sender, stakeInfo.stakeNumber);
            stakeInfo.stakeNumber = 0;
        }
        // 修改利润和最新质押时间
        stakeInfo.stakeStartTime = block.timestamp;
        stakeInfo.unClaimNumber = 0;
        stakePools[msg.sender] = stakeInfo;
    }

    // 计算收益（未领取的质押数量，当前质押的收益）
    function stakingIncome(StakeInfoStruct memory stakeInfo) public view returns (uint256 income) {
        uint256 stakeTime = block.timestamp - stakeInfo.stakeStartTime;
        return stakeInfo.stakeNumber * stakeTime * profitPerSeconds;
    }

    modifier hadStaked() {
        StakeInfoStruct memory stakeInfo = stakePools[msg.sender];
        require(stakeInfo.stakeNumber > 0, "not stake");
        _;
    }
}

/**
 * 与用户的交互：
 * 1、用户质押； --> 可追加
 * 2、用户点领取；--> esRNT 到用户 EOA账户；同时在合约上 记录一个【兑换订单】(产生时间)
 * 3、用户点兑换。--> 用户在合约上点【兑换订单】，根据时长条件，消耗esRNT生成对应比例的RNT
 */
