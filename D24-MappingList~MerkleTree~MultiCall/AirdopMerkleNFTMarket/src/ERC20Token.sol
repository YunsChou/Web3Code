// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ERC20Token is ERC20, ERC20Permit {
    constructor() ERC20("ERC20Token", "ERC20") ERC20Permit("ERC20Token") {}

    // 用来生成 签名消息
    function getPermitDigest(address _owner, address _spender, uint256 _value, uint256 _deadline)
        external
        view
        returns (bytes32 digest)
    {
        // 打包消息
        bytes32 permit_hash =
            keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        bytes32 structHash = keccak256(abi.encode(permit_hash, _owner, _spender, _value, nonces(_owner), _deadline));
        // 签名消息
        digest = _hashTypedDataV4(structHash);
    }
}
