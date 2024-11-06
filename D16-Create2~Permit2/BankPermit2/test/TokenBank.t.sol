// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {MockERC20} from "forge-std/mocks/MockERC20.sol";
import "../src/TokenBank.sol";

// interface IAllowanceTransfer {
//     function approve(address token, address spender, uint160 amount, uint48 expiration) external;
// }

contract TokenBankTest is Test {
    address permit2Contract = address(0x000000000022D473030F116dDEE9F6B43aC78BA3);
    bytes32 public constant _PERMIT_TRANSFER_FROM_TYPEHASH = keccak256(
        "PermitTransferFrom(TokenPermissions permitted,address spender,uint256 nonce,uint256 deadline)TokenPermissions(address token,uint256 amount)"
    );
    bytes32 public constant _TOKEN_PERMISSIONS_TYPEHASH = keccak256("TokenPermissions(address token,uint256 amount)");
    // bytes32 public constant _PERMIT_DETAILS_TYPEHASH =
    //     keccak256("PermitDetails(address token,uint160 amount,uint48 expiration,uint48 nonce)");

    TokenBank public bank;
    address public alice;
    uint256 public userPK;
    MockERC20 public mockToken;
    uint256 public constant dealTokenAmount = 1e10 * 1e18; //100000;

    function setUp() public {
        bank = new TokenBank(permit2Contract);

        (alice, userPK) = makeAddrAndKey("alice");
        console.log("-->> alice: ", alice);
        console.log("-->> userPK: ", userPK);

        mockToken = deployMockERC20("YYToken", "YYT", 18);

        deal(address(mockToken), alice, dealTokenAmount);

        // 用户授权额度到Permit2合约
        vm.prank(alice);
        mockToken.approve(permit2Contract, type(uint256).max);

        // 【！！！】用Permit2中的approve会出问题
        // IPermit2(permit2Contract).approve(
        //     address(mockToken), permit2Contract, type(uint160).max, uint48(block.timestamp + 10 hours)
        // );
    }

    function test_depositWithPermit2() public {
        // 存款额度
        uint256 depositAmount = 100;

        // 构造用户签名信息
        IPermit2.TokenPermissions memory permitted =
            IPermit2.TokenPermissions({token: address(mockToken), amount: depositAmount});
        IPermit2.PermitTransferFrom memory permitTrans = IPermit2.PermitTransferFrom({
            permitted: permitted,
            nonce: block.timestamp,
            deadline: block.timestamp + 1 hours
        });
        // ISignatureTransfer.SignatureTransferDetails memory signatureTrans = ISignatureTransfer.SignatureTransferDetails(address(bank), 100);
        bytes memory signature = signToPermit2(permitTrans);

        // 验签并完成存款
        vm.startPrank(alice);

        bank.depositWithPermit2(address(mockToken), depositAmount, permitTrans, signature);
        vm.stopPrank();

        // 检查结果
        uint256 aliceBalance = mockToken.balanceOf(alice);
        uint256 aliceBankAmount = bank.addrAmount(alice, address(mockToken));
        require(aliceBankAmount == depositAmount, "deposit amount error");
        require(aliceBalance == dealTokenAmount - depositAmount, "alice balance error");
    }

    // 签名方式在Permit中的getPermitTransferSignature
    function signToPermit2(IPermit2.PermitTransferFrom memory permit) public view returns (bytes memory signature) {
        bytes32 domainSeparator = IPermit2(permit2Contract).DOMAIN_SEPARATOR();
        console.log("-->> domainSeparator: ", bytes32ToString(domainSeparator));
        bytes32 msgHash = keccak256(abi.encodePacked("\x19\x01", domainSeparator, _hashTokenPermitTransferFrom(permit)));
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(userPK, msgHash);
        signature = bytes.concat(r, s, bytes1(v));
    }

    function _hashTokenPermitTransferFrom(IPermit2.PermitTransferFrom memory permit) private view returns (bytes32) {
        return keccak256(
            abi.encode(
                _PERMIT_TRANSFER_FROM_TYPEHASH,
                _hashTokenPermissions(permit.permitted),
                address(bank),
                permit.nonce,
                permit.deadline
            )
        );
    }

    function _hashTokenPermissions(IPermit2.TokenPermissions memory permitted) private pure returns (bytes32) {
        bytes32 hash1 = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted.token, permitted.amount));
        bytes32 hash2 = keccak256(abi.encode(_TOKEN_PERMISSIONS_TYPEHASH, permitted));
        console.log("-->> hash1: ", bytes32ToString(hash1));
        console.log("-->> hash2 ", bytes32ToString(hash2));
        require(hash1 == hash2, "hash1 != hash2");
        console.log("-->> hash1 == hash2");
        return hash2;
    }

    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        bytes memory bytesArray = new bytes(32);
        for (uint256 i = 0; i < 32; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}
