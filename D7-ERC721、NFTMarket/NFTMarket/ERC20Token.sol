// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

interface IERC20Receiver {
    // 此时 msg.sender是ERC20合约地址，operator是调用者（用户）地址，from是调用者（用户）地址
    function tokensReceived(address operator, address from, uint256 value, bytes calldata data)
        external
        returns (bytes4);
}

contract ERC20Token {
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
    // 【用户调用】：此时 msg.sender调用者（用户）地址，to 是收款合约地址
    function transferWithCallback(address to, uint256 amount, bytes memory data) public {
        if (!transfer(to, amount)) {
            revert ERC20InvalidSpender(to);
        }
        // 检测回调方法：此时 msg.sender调用者（用户）地址，to 是收款合约地址
        _checkOnERC20Received(msg.sender, msg.sender, to, amount, data);
    }

    // 检查IBERC20Receiver方法是否实现（如果实现触发callback）
    function _checkOnERC20Received(address operator, address from, address to, uint256 value, bytes memory data)
        internal
    {
        if (to.code.length == 0) {
            revert ERC20InvalidSpender(to);
        }
        // 触发回调方法：to 是收款合约地址，
        // 传入tokensReceived参数：operator是调用者（用户）地址，from 是调用者（用户）地址
        // 触发tokensReceived回调参数：msg.sender是ERC20合约地址，operator是调用者（用户）地址，from是调用者（用户）地址
        try IERC20Receiver(to).tokensReceived(operator, from, value, data) returns (bytes4 retval) {
            if (retval != IERC20Receiver.tokensReceived.selector) {
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

/**
 * 参照IERC1363的实现callBack
 * https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/ERC1363.sol
 * https://github.com/vittominacori/erc1363-payable-token/blob/master/contracts/token/ERC1363/ERC1363Utils.sol
 *
 *     function transferAndCall(address to, uint256 value, bytes memory data) public virtual returns (bool) {
 *         if (!transfer(to, value)) {
 *             revert ERC1363Utils.ERC1363TransferFailed(to, value);
 *         }
 *         ERC1363Utils.checkOnERC1363TransferReceived(_msgSender(), _msgSender(), to, value, data);
 *         return true;
 *     }
 *
 *      function checkOnERC1363TransferReceived(
 *         address operator,
 *         address from,
 *         address to,
 *         uint256 value,
 *         bytes memory data
 *     ) internal {
 *         if (to.code.length == 0) {
 *             revert ERC1363EOAReceiver(to);
 *         }
 *
 *         try IERC1363Receiver(to).onTransferReceived(operator, from, value, data) returns (bytes4 retval) {
 *             if (retval != IERC1363Receiver.onTransferReceived.selector) {
 *                 revert ERC1363InvalidReceiver(to);
 *             }
 *         } catch (bytes memory reason) {
 *             if (reason.length == 0) {
 *                 revert ERC1363InvalidReceiver(to);
 *             } else {
 *                 assembly {
 *                     revert(add(32, reason), mload(reason))
 *                 }
 *             }
 *         }
 *     }
 */
