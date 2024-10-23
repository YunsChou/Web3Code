// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MyBank {
    address private _owner; // 记录合约所有者
    mapping(address => uint256) public addressAmount; // 记录每个地址转账额度
    uint256 public totalAmountRecord; // 记录该合约转入总额度

    uint256[3] private _top3Amount; // 记录top3转账额度（可累加）
    address[3] private _top3Address; // 记录top3地址

    event RecordOwner(address indexed owner);
    event TransferReceived(address indexed sender, uint256 amount, uint256 totalBalance);

    receive() external payable { 
        // 记录转账地址额度
        addressAmount[msg.sender] += msg.value;
        // 记录存入总额度
        totalAmountRecord += msg.value;
        // 更新top3
        updateTop3(msg.sender, addressAmount[msg.sender]);
        // 触发事件
        emit TransferReceived(msg.sender, msg.value, addressAmount[msg.sender]);
    }

    constructor() {
        // 记录合约所有者地址
        _owner = msg.sender;
        emit RecordOwner(_owner);
    }

    // 判断是否管理员
    modifier onlyOwner() {
        require(msg.sender == _owner, "is not manager");
        _;
    }

    // 查询管理员地址
    function queryOwnderAddress() external view returns (address) {
        return _owner;
    }

    // （管理员）提现
    function withdraw(uint256 amount) external payable onlyOwner {
        require(address(this).balance > amount, "remaining amount is not enought"); // 判断剩余额度是否足够
        payable(_owner).transfer(amount);
    }

    // 查询合约帐户余额
    function queryContractAmount() external view returns (uint256) {
        return address(this).balance;
    }

    // 接收转账更新top3记录
    function updateTop3(address senderAddress, uint256 senderAmount) internal {
        for (uint256 i = 0; i < 3; i ++) 
        {
            if (senderAmount > _top3Amount[i]) {
               
                for (uint256 j = 2; j > i; j --) 
                {
                     _top3Amount[j] = _top3Amount[j - 1];
                     _top3Address[j] = _top3Address[j - 1];
                }
                _top3Amount[i] = senderAmount;
                _top3Address[i] = senderAddress;
                break;
            }
        }
    }

    // 记录转账额度前3的帐户地址
    function queryTop3() external view returns (address[3] memory, uint256[3] memory) {
        return (_top3Address, _top3Amount);
    }
}
