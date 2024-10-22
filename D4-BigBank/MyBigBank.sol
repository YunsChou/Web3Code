// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

// 定义bank接口
interface IBank {
    // 查询管理员地址
    function queryOwnderAddress() external view returns (address);
    // 查询合约帐户余额
    function queryContractAmount() external view returns (uint256);
    // 记录转账额度前3的帐户地址
    function queryTop3() external view returns (address[3] memory);
    // 资金转移到调用者合约
    function withdrawToAdmin() external payable;
}

// 公用方法抽象出来复用
abstract contract MsgContext {
    address internal _owner; // 记录合约所有者
    // 当前调用者地址
    function _msgSend() internal view returns (address) {
        return msg.sender;
    }

    // 判断是否管理员
    modifier onlyOwner() {
        
        require(_msgSend() == _owner, "is not owner");
        _;
    }

    // 判断是否大于一定额度
    modifier miniValueLimit(uint256 amount) virtual  {
        require(amount > 0, "sender value must more than 0 eth");
        _;
    }
}

contract MyBank is IBank, MsgContext {
    mapping(address => uint256) public addressAmount; // 记录每个地址转账额度

    address[3] private _top3Address; // 记录top3地址

    event RecordOwner(address indexed owner);
    event TransferReceived(address indexed sender, uint256 amount, uint256 totalBalance);
    error TransCallFail();


    receive() external payable miniValueLimit(msg.value) {
        // 记录转账地址额度
        addressAmount[_msgSend()] += msg.value;
        // 更新top3
        updateTop3(_msgSend(), addressAmount[_msgSend()]);
        // 触发事件
        emit TransferReceived(_msgSend(), msg.value, addressAmount[_msgSend()]);
    }

    constructor() {
        // 记录合约所有者地址
        _owner = _msgSend();
        emit RecordOwner(_owner);
    }


    // 查询管理员地址
    function queryOwnderAddress() external view returns (address) {
        return _owner;
    }

    // 提取余额到管理员合约
    function withdrawToAdmin() external payable onlyOwner {
        uint256 amount = address(this).balance;
        this.withdraw(_owner, amount);
    }

    // （管理员）提现
    function withdraw(address toAddress, uint256 amount) external payable {
        require(_owner == toAddress, "address is not admin");
        require(address(this).balance >= amount, "remaining amount is not enought"); // 判断剩余额度是否足够
        (bool succ,) = payable(toAddress).call{value: amount}("");
        if (!succ) {
            revert TransCallFail();
        }
    }

    // 查询合约帐户余额
    function queryContractAmount() external view returns (uint256) {
        return address(this).balance;
    }

    // 接收转账更新top3记录
    function updateTop3(address senderAddress, uint256 senderAmount) internal {
        for (uint256 i = 0; i < 3; i ++) 
        {
            address indexAddress = _top3Address[i];
            if (senderAmount > addressAmount[indexAddress]) {
               
                for (uint256 j = 2; j > i; j --) 
                {
                     _top3Address[j] = _top3Address[j - 1];
                }
                _top3Address[i] = senderAddress;
                break;
            }
        }
    }

    // 记录转账额度前3的帐户地址
    function queryTop3() external view returns (address[3] memory) {
        return (_top3Address);
    }
}

contract BigBank is MyBank {
    constructor() {
        // 记录合约所有者地址
        _owner = _msgSend();
        emit RecordOwner(_owner);
    }

    // 判断是否大于一定额度
    modifier miniValueLimit(uint256 amount) override {
        require(amount > 0.001 * 10**18, "sender value must more than 0.001 eth");
        _;
    }
    // 转移管理员：新管理员地址
    function transferOwnership(address newOwner) external payable onlyOwner {
        _owner = newOwner;
    }
}

contract Admin is MsgContext {
    receive() external payable {
        
    }

    constructor() {
        // 记录合约所有者地址
        _owner = _msgSend();
    }
    // 管理员提取 某个bank 合约全部余额
    function adminWithdraw(IBank bank) external payable onlyOwner {
        bank.withdrawToAdmin();
    }
    // 查询合约余额
    function queryAdminBalance() external view  returns (uint256) {
        return address(this).balance;
    }

    // 查询管理员地址
    function queryOwnderAddress() external view returns (address) {
        return _owner;
    }
}