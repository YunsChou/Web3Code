// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract esRNToken is ERC20 {
    struct LockInfo {
        uint64 startTime;
        uint256 amount;
    }

    mapping(address => LockInfo[]) public lockInfos;
    address public stakingToken;

    constructor() ERC20("esRNToken", "esRNT") {}

    function initialize(address _stakingToken) external {
        stakingToken = _stakingToken;
    }

    // 谁有mint权限？
    function mint(address account, uint256 value) external {
        _mint(account, value);
    }

    function burn(address account, uint256 value) external {
        _burn(account, value);
    }

    function exchangeToRNT(uint8[] memory indexs) external {
        LockInfo[] memory userLockInfo = lockInfos[msg.sender];
        require(indexs.length <= userLockInfo.length, "indexs more than list");

        uint256 lockAmount = 0;
        uint256 exchangeAmount = 0;
        for (uint8 i = 0; i < indexs.length; i++) {
            uint8 index = indexs[i];

            LockInfo memory lockInfo = userLockInfo[index];
            require(lockInfo.amount > 0, "no lock amount");

            lockAmount += lockInfo.amount;
            exchangeAmount += checkExchangeRNTAmount(lockInfo);
        }

        _burn(msg.sender, lockAmount);

        _transfer(stakingToken, msg.sender, exchangeAmount);
    }

    function checkExchangeRNTAmount(LockInfo memory lockInfo) public view returns (uint256) {
        uint256 holdDay = (block.timestamp - lockInfo.startTime) / (24 * 60 * 60);
        uint256 exchangeRate = 0;
        if (holdDay >= 30) {
            exchangeRate = 1;
        } else {
            exchangeRate = holdDay / 30;
        }
        return exchangeRate * lockInfo.amount;
    }
}
