// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

import "forge-std/console.sol";

struct LockInfo {
    uint256 amount;
    uint256 startTime;
}

contract esRNToken is ERC20 {
    address public owner;
    mapping(address => LockInfo[]) public lockInfos;
    address public stakingToken;

    // 给当前合约设置admins，是admin可以执行铸币
    mapping(address => bool) public admins;

    constructor() ERC20("esRNToken", "esRNT") {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(owner == msg.sender, "is not owner");
        _;
    }

    modifier onlyAdmin() {
        console.log("-->> onlyAdmin msg.sender:", msg.sender);
        console.log("-->> onlyAdmin admins[msg.sender]:", admins[msg.sender]);
        require(admins[msg.sender], "is not admin");
        _;
    }

    function addAdmin(address account, bool havePermission) external onlyOwner {
        admins[account] = havePermission;
        console.log("-->> addAdmin admins[account]:", admins[account]);
    }

    function initialize(address _stakingToken) external onlyOwner {
        stakingToken = _stakingToken;
    }

    function mint(address account, uint256 value) external onlyAdmin {
        _mint(account, value);

        // 锁仓
        lockInfos[account].push(LockInfo({amount: value, startTime: block.timestamp}));
    }

    // 选择需要兑换的下标进行兑换（esRNT --> RNT），支持批量
    // web2查询lockInfos，处理可选下标（没有兑换额度的、不满一天的等）
    function convertToRNT(uint8[] memory indexs) external {
        LockInfo[] memory userLockInfo = lockInfos[msg.sender];
        require(indexs.length <= userLockInfo.length, "indexs more than list");

        uint256 lockAmount = 0;
        uint256 convertAmount = 0;
        for (uint8 i = 0; i < indexs.length; i++) {
            uint8 index = indexs[i];

            LockInfo memory lockInfo = userLockInfo[index];
            // require(lockInfo.amount > 0, "no lock amount"); // web2处理
            // 记录要销毁和兑换的额度
            lockAmount += lockInfo.amount;
            convertAmount += calcConvertRNTAmount(lockInfo);

            // 将锁仓的额度改为 0
            lockInfo.amount = 0;
        }
        // 要求销毁的锁仓esRNT额度和兑换的RNT额度都要 > 0，否则没意义
        require(lockAmount > 0, "lockAmount is 0");
        require(convertAmount > 0, "convertAmount is 0");

        // 销毁esRNT
        _burn(msg.sender, lockAmount);
        // 转账RNT
        IERC20(stakingToken).transfer(msg.sender, convertAmount);
    }

    // 计算锁仓可兑换额度
    // web2处理不满1天的不可选
    function calcConvertRNTAmount(LockInfo memory lockInfo) public view returns (uint256) {
        uint256 holdTime = block.timestamp - lockInfo.startTime;
        if (holdTime >= 30 days) {
            return lockInfo.amount;
        } else {
            // 支持30天内线性释放
            console.log("holdTime:", holdTime);
            console.log("holdDay:", holdTime / 30 days);
            return (lockInfo.amount * holdTime) / 30 days;
        }
    }

    // [该查询不可可直接调用lockInfos获取?]获取账户的锁仓列表。web2处理可选择兑换下标等（有兑换额度的）
    function checkLockList(address account) external view returns (LockInfo[] memory) {
        return lockInfos[account];
    }
}
