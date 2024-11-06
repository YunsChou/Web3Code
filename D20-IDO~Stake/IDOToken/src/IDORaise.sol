// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./RNTToken.sol";

contract IDORaise {
    address public owner;
    RNTToken public rntToken;

    // 筹集资金分配
    uint256 constant ratioTotal = 100;
    uint256 public ratioCount;
    mapping(address => uint256) partyRatio;
    // 筹集eth
    bool public isEnd;
    uint256 public totalETH;
    mapping(address => uint256) balances;

    // 预售配置
    uint256 constant preRNTPrice = 0.0001 ether; // 预售价格
    uint256 constant preRNTTotal = 100 * 10000; // 预售RNT数量
    uint256 constant minETHAmount = 0.01 ether; // 最低买入
    uint256 constant maxETHAmount = 0.1 ether; // 最高买入
    uint256 constant minETHTarget = 100 ether; // 最低募集目标
    uint256 constant maxETHTarge = 200 ether; // 最高募集目标

    constructor() {
        owner = msg.sender;
        rntToken = new RNTToken();
    }

    receive() external payable {
        preSale();
    }

    // 记录预售款
    function preSale() public payable onlyActive singleAmountLimit(msg.value) {
        balances[msg.sender] += msg.value;

        totalETH += msg.value;

        // 筹集到最高额度，募集结束
        if (totalETH >= 200 ether) {
            isEnd = true;
        }
    }

    // 项目方设置各方提取比例
    function withdrawalRatio(address spender, uint256 amount) external onlyOwner {
        require(ratioCount < ratioTotal, "ratio percent error");
        ratioCount += amount;
        require(ratioCount > ratioTotal, "ratio percent exceed");
        partyRatio[spender] = amount;
    }

    // 主动触发结束（项目方手动，或募集时间截止）
    function raiseFinish() external onlyOwner {
        isEnd = true;
    }

    // 预售成功情况下，给用户转币
    function claim() external onlySuccess {
        uint256 perShare = preRNTTotal / totalETH;
        require(balances[msg.sender] > 0, "your balances is 0");
        uint256 userShare = perShare * balances[msg.sender];

        rntToken.transfer(msg.sender, userShare);
    }

    // 预售失败情况下，给用户退款（用户自己来领取退款？）
    function refund() external onlyFail {
        (bool succ,) = payable(msg.sender).call{value: balances[msg.sender]}("");
        require(succ, "refund fail");
    }

    // 预售成功，项目方、开发团队各自提款
    function withdraw() external onlySuccess {
        uint256 ratio = partyRatio[msg.sender];
        require(ratio > 0, "no withdrawal share");
        uint256 ratioShare = ratio / 100 * totalETH;
        (bool succ,) = payable(msg.sender).call{value: ratioShare}("");
        require(succ, "withdraw fail");
    }

    // 预估rnt发行价格（eth计价）
    function estAmount(uint256 eths) external pure returns (uint256) {
        return preRNTTotal * eths / (minETHTarget + eths);
    }

    modifier onlyOwner() {
        require(msg.sender != address(0), "msg.sender is 0x");
        require(msg.sender == owner, "msg.sender is not owner");
        _;
    }

    modifier singleAmountLimit(uint256 amount) {
        require(amount >= minETHAmount && amount <= maxETHAmount, "amount is Not eligible");
        _;
    }

    modifier onlySuccess() {
        require(isEnd && totalETH >= 100 ether, "not onlySuccess");
        _;
    }

    modifier onlyFail() {
        require(isEnd && totalETH < 100 ether, "not onlyFail");
        _;
    }

    modifier onlyActive() {
        require(!isEnd && totalETH < 100 ether, "not onlyActive");
        _;
    }
}
