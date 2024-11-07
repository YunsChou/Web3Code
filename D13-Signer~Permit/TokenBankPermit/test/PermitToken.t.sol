// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "../src/PermitToken.sol";

contract PermitTokenTest is Test {
    PermitToken public token;
    address public owner;

    uint256 public privateKey = 0x123;

    function setUp() public {
        token = new PermitToken();
        // 设置私钥生成用户
        owner = vm.addr(privateKey);
        vm.label(owner, "xiaoming");
        token.mint(owner, 10000 * 10 ** 18);
    }

    function test_tokenAmount() external view {
        assertEq(token.totalSupply(), 10000 * 10 ** 18, "totalSupply is error");
    }

    function test_permit() external {
        address spender = address(2);
        vm.label(spender, "xiaohong");
        uint256 spendValue = 20 * 10 ** 18;
        uint256 deadline = block.timestamp + 3 hours;

        // 用户1
        vm.startPrank(owner);
        // 以太坊签名消息
        bytes32 msgHash = token.getPermitDigest(owner, spender, spendValue, deadline);
        // 使用私钥签名, 获取 rsv
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privateKey, msgHash);

        vm.stopPrank();

        // 用户2
        vm.startPrank(spender);
        // 执行permit
        token.permit(owner, spender, spendValue, deadline, v, r, s);
        vm.stopPrank();

        // 检查结果
        console.log("-->> token.allowance: ", token.allowance(owner, spender));
        assertEq(token.allowance(owner, spender), spendValue, "permit approve value error");
    }
}
