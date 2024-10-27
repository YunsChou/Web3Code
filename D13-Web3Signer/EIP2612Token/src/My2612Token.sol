// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
// import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract My2612Token is ERC20, EIP712 {
    // _hashTypedDataV4 在 EIP712 中

    // using ECDSA for bytes32;

    // struct Permit {
    //     address owner;
    //     address spender;
    //     uint256 value;
    //     uint256 nonce;
    //     uint256 deadline;
    // }

    mapping(address => uint256) private _ownerNonce;
    bytes32 private constant _PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 nonce,uint256 deadline");
    string private constant EIP712Name = "YY721";
    string private constant EIP712Version = "1";

    constructor() ERC20("YYToken", "YYT") EIP712(EIP712Name, EIP712Version) {}

    function mint(address to, uint256 value) external {
        _mint(to, value);
    }

    function permit(address owner, address spender, uint256 value, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
        external
    {
        require(deadline > block.timestamp, "expired deadline");
        // 打包消息
        bytes32 structHash =
            keccak256(abi.encodePacked(_PERMIT_TYPEHASH, owner, spender, value, _ownerNonce[owner], deadline));
        // 签名消息
        bytes32 msgHash = _hashTypedDataV4(structHash);

        // 使用 签名消息 和 rsv(从签名结果中读取)，恢复signer
        address signer = ECDSA.recover(msgHash, v, r, s);
        require(signer == owner, "signer is not permit owner");

        _ownerNonce[owner] += 1;

        // 验签通过，执行授权
        _approve(owner, spender, value);
    }

    function getPermitDigest(address owner, address spender, uint256 value, uint256 deadline)
        external
        view
        returns (bytes32 digest)
    {
        // 打包消息
        bytes32 structHash =
            keccak256(abi.encodePacked(_PERMIT_TYPEHASH, owner, spender, value, _ownerNonce[owner], deadline));
        digest = _hashTypedDataV4(structHash);
    }
}
