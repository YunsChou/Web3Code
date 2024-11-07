// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract TokenBank {
    ERC20Permit public token;
    mapping(address => uint256) public addressAmount; // 记录每个地址转账额度

    constructor(ERC20Permit _token) {
        token = _token;
    }

    // 存款到合约
    function deposit(uint256 amount) external payable {
        token.transferFrom(msg.sender, address(this), amount);
        addressAmount[msg.sender] += amount;
    }

    // 从合约提款
    function withdraw(uint256 amount) external payable {
        require(addressAmount[msg.sender] >= amount, "balance is not enougth");
        token.transfer(msg.sender, amount);
        addressAmount[msg.sender] -= amount;
    }

    
    function permitDeposit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external payable {
        require(owner == msg.sender, "is not owner");
        require(spender == address(this), "spender is no the bank contract");
        // 验签通过，并执行授权
        token.permit(owner, spender, value, deadline, v, r, s);

        // 执行授权转账
        token.transferFrom(owner, spender, value);
        addressAmount[msg.sender] += value;
    }
}
