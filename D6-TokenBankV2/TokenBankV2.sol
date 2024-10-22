// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract BaseERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;

    uint256 public totalSupply;

    mapping(address => uint256) balances;

    mapping(address => mapping(address => uint256)) allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    error ERC20InvalidSpender(address spender);

    constructor() {
        // write your code here
        // set name,symbol,decimals,totalSupply
        name = "BaseERC20";
        symbol = "BERC20";
        decimals = 18;
        totalSupply = 100000000 * 10 ** decimals;
        balances[msg.sender] = totalSupply;
    }

    function balanceOf(address _owner) public view returns (uint256 balance) {
        // write your code here
        return balances[_owner];
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[msg.sender] >= _value, "ERC20: transfer amount exceeds balance");
        balances[msg.sender] -= _value;
        balances[_to] += _value;

        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        // write your code here
        require(balances[_from] >= _value, "ERC20: transfer amount exceeds balance");
        require(allowances[_from][msg.sender] >= _value, "ERC20: transfer amount exceeds allowance");

        allowances[_from][msg.sender] -= _value;

        balances[_from] -= _value;
        balances[_to] += _value;

        emit Transfer(_from, _to, _value);

        return true;
    }

    function approve(address _spender, uint256 _value) public returns (bool success) {
        // write your code here
        allowances[msg.sender][_spender] = _value;

        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) public view returns (uint256 remaining) {
        // write your code here
        return allowances[_owner][_spender];
    }

    // 新增扩展方法：调用完转账，触发callBack
    function transferWithCallback(address to, uint256 amount) public {
        if (!transfer(to, amount)) {
            revert ERC20InvalidSpender(to);
        }

        _checkOnERC20Received(msg.sender, to, amount, "");
    }
    /**
     * 往合约转账 + callback记录转账{地址:额度} = 给合约授权额度 + （从授权额度）往合约存款记录{地址:额度}
     * 一步到位，省去了授权步骤，且更加安全（无授权额度由他人控制）
     *
     * _checkOnERC20Received参数解析：from（存款者）、to（收款者）、value（额度）、...
     * to（收款者）用来调用触发callback方法、from和value用来记录{地址:额度}
     * 可以直接用收款者的withdraw进行提款
     *
     * 如果没有先授权额度approve，无法直接使用收款者的deposit进行存款
     */

    // 检查IBERC20Receiver方法是否实现（如果实现触发callback）
    function _checkOnERC20Received(address from, address to, uint256 value, bytes memory data) internal {
        if (to.code.length == 0) {
            revert ERC20InvalidSpender(to);
        }

        try IBERC20Receiver(to).tokensReceived(msg.sender, from, value, data) returns (bytes4 retval) {
            if (retval != IBERC20Receiver.tokensReceived.selector) {
                revert ERC20InvalidSpender(to);
            }
        } catch (bytes memory reason) {
            if (reason.length == 0) {
                revert ERC20InvalidSpender(to);
            } else {
                assembly {
                    revert(add(32, reason), mload(reason))
                }
            }
        }
    }
}

contract TokenBank {
    BaseERC20 public bToken;
    mapping(address => uint256) public addressAmount; // 记录每个地址转账额度

    constructor(BaseERC20 _bToken) {
        bToken = _bToken;
    }

    // 存款到合约
    function deposit(uint256 amount) external payable {
        bToken.transferFrom(msg.sender, address(this), amount);
        addressAmount[msg.sender] += amount;
    }

    // 从合约提款
    function withdraw(uint256 amount) external payable {
        require(addressAmount[msg.sender] > amount, "balance is not enougth");
        bToken.transfer(msg.sender, amount);
        addressAmount[msg.sender] -= amount;
    }
}

interface IBERC20Receiver {
    function tokensReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        returns (bytes4);
}

contract TokenBankV2 is TokenBank, IBERC20Receiver {
    constructor(BaseERC20 _bToken) TokenBank(_bToken) {}

    function tokensReceived(address, address from, uint256 amount, bytes calldata) external returns (bytes4) {
        require(msg.sender == address(bToken), "Only the specified token can call this");
        addressAmount[from] += amount;
        return this.tokensReceived.selector;
    }
}
