// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract PermitToken is ERC20Permit {
    constructor() ERC20("YYToken", "YYT") ERC20Permit("YY20") {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

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

        digest = _hashTypedDataV4(structHash);
    }
}