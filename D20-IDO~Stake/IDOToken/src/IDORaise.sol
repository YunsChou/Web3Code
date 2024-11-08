// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract IDORaise {
    address public owner;
    IERC20 public rntToken;

    // 募集进度
    bool public isEnd;
    uint256 public totalETH;
    mapping(address => uint256) public balances;
    uint256 public endTime;

    // 预售配置
    uint256 constant preRNTTotal = 1000000 * 1e18; // 预售RNT数量
    uint256 constant minETHTarget = 100 ether; // 最低募集目标
    uint256 constant maxETHTarge = 200 ether; // 最高募集目标
    uint256 constant preRNTPrice = preRNTTotal / minETHTarget; // 预售价格

    uint256 constant minETHAmount = 0.01 ether; // 最低买入
    uint256 constant maxETHAmount = 0.1 ether; // 最高买入

    constructor(address _idoToken) {
        owner = msg.sender;
        rntToken = IERC20(_idoToken);
        endTime = block.timestamp + 10 days;
    }

    receive() external payable {
        preSale();
    }

    // 记录预售款
    function preSale() public payable onlyActive singleAmountLimit(msg.value) {
        balances[msg.sender] += msg.value; // 有用户多次申购

        totalETH += msg.value;
        // 筹集到最高额度，募集结束
        if (totalETH >= 200 ether) {
            isEnd = true;
        }
    }

    // 主动触发结束（项目方手动结束）
    function raiseFinish() external onlyOwner {
        isEnd = true;
    }

    // 预售成功情况下，给用户转币（用户主动来领币）
    function claim() external onlySuccess {
        uint256 realPrice = realRNTPrice();
        require(balances[msg.sender] > 0, "your balances is 0");
        uint256 userAmount = balances[msg.sender] / realPrice;
        balances[msg.sender] = 0;
        rntToken.transfer(msg.sender, userAmount);
    }

    // 预售失败情况下，给用户退款（用户自己来领取退款）
    function refund() external onlyFail {
        uint256 eths = balances[msg.sender];
        if (eths > 0) {
            balances[msg.sender] = 0;
            // 退款 失败 【因为balances是动态变化的，执行transfer会失败】
            // payable(msg.sender).transfer(balances[msg.sender]);

            // 退款 成功
            (bool succ,) = payable(msg.sender).call{value: eths}("");
            require(succ, "refund fail");
        }
    }

    // 项目方提取eth
    function withdraw() external onlySuccess onlyOwner {
        // 此时totalETH 和 address(this).banlance 的值应该相等
        uint256 eths = address(this).balance;
        // 提取
        (bool succ,) = payable(owner).call{value: eths}("");
        require(succ, "admin withdraw fail");
    }

    // 预售成功，rnt实际价格
    function realRNTPrice() public view returns (uint256) {
        return preRNTTotal / totalETH;
    }

    // 预售成功，计算认购eth数量，实际领rnt数量
    function realClaimAmount(uint256 eths) public view returns (uint256) {
        return eths / realRNTPrice();
    }

    // 预售成功情况下，用户可以领到的rnt数量
    function estClaimAmount(address user) public view returns (uint256) {
        return balances[user] / estRNTPrice(balances[user]);
    }

    // 预估rnt发行价格（eth计价）
    function estRNTPrice(uint256 eths) public view returns (uint256) {
        // 预估价格 = 预售价格 * 当前募集的eth / (当前募集的eth + 新增的eth)
        return preRNTTotal * eths / (totalETH + eths);
    }

    function checkIsEnd() public returns (bool) {
        if (isEnd) {
            return true;
        }
        if (block.timestamp > endTime) {
            isEnd = true;
            return true;
        }
        return false;
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
        require(checkIsEnd() && totalETH >= 100 ether, "not onlySuccess");
        _;
    }

    modifier onlyFail() {
        require(checkIsEnd() && totalETH < 100 ether, "not onlyFail");
        _;
    }

    modifier onlyActive() {
        require(!checkIsEnd() && totalETH < 200 ether, "not onlyActive");
        _;
    }
}
