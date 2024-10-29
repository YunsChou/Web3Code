// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract ERC20Bank {
    address public _owner;

    constructor() {
        _owner = msg.sender;
    }

    receive() external payable {}

    // 判断是否管理员
    modifier onlyOwner() {
        require(msg.sender == _owner, "is not owner");
        _;
    }

    function changeAdmin(address newAdmin) external onlyOwner {
        _owner = newAdmin;
    }

    // function withdrawToAdmin() external {
    //     uint256 amount = address(this).balance;
    //     require(amount > 0, "amount is not enought");
    //     payable(_owner).transfer(amount);
    //     // this.withdraw(_owner, amount);
    // }

    function withdrawToAdmin() external {
        uint256 amount = address(this).balance;
        require(amount > 0, "amount is not enought");
        // this.withdraw(_owner, amount);
        withdraw(_owner, amount);
    }

    function withdraw(address to, uint256 amount) internal onlyOwner {
        require(to != address(0), "address is 0x");
        require(address(this).balance >= amount, "balance is not enought");
        // (bool succ,) = payable(to).call{value: amount}("");
        // require(succ, "call trans fail");
        payable(to).transfer(amount);
    }

    function getBankBalance() external view returns (uint256) {
        return address(this).balance;
    }
}
