// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract WalletMultSigner {
    event Deposit(address indexed sender, uint amount, uint balance);
    event ExecuteTransaction(
        address indexed to,
        uint value,
        bytes data
    );

    struct Propose {
        address to;
        uint256 value;
        bytes data;
    }
  
    mapping(address => bool) public isOwner;
    uint256 public minConfirm;

    uint256 public _proposeId;
    mapping(uint256 => Propose) public proposes;

    mapping(uint256 => uint256) public confirms;

    mapping(uint256 => mapping(address => bool)) public isConfirmed; // 记录该提按，该用户是否已批准


    modifier onlySigner() {
        require(isOwner[msg.sender], "is not signer");
        _;
    }

    constructor(address[] memory _owners, uint256 _minConfirm) {
        require(_owners.length >= _minConfirm, "_owners count less than minConfirm");
        
        // owners = _owners;
        minConfirm = _minConfirm;
        for (uint i = 0; i < _owners.length; i ++) 
        {
            address owner = _owners[i];
            isOwner[owner] = true;
        }
    }

    receive() external payable {
        emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    // 发起提案
    function proposeTransaction(
        address _to,
        uint256 _value,
        bytes memory _data
    ) public onlySigner {
        // 记录提案
        _proposeId ++;
        proposes[_proposeId] = Propose(_to, _value, _data);
        // 提案确认+1
        signerConfirmed(_proposeId);
    }

    // 确认提案
    function confirm(uint256 proposeId) external onlySigner {
        // 判断不是已经确认过的用户
        require(!isConfirmed[proposeId][msg.sender], "you had confirmed");
        // 提案确认+1
        signerConfirmed(proposeId);
    }

    // 确认提案行为：该提案 确认次数+1，记录已确认用户
    function signerConfirmed(uint256 proposeId) internal onlySigner {
        confirms[proposeId] += 1;
        isConfirmed[proposeId][msg.sender] = true;

        if (confirms[proposeId] >= minConfirm) {
            Propose memory propose = proposes[proposeId];
            executeTransaction(propose.to, propose.value, propose.data);
        }
    }

    // 执行提案
    function executeTransaction(
        address _to,
        uint _value,
        bytes memory _data
    ) public {

        (bool success, ) = _to.call{value: _value}(
            _data
        );
        
        require(success, "tx failed");

        emit ExecuteTransaction(_to, _value, _data);

    }
}