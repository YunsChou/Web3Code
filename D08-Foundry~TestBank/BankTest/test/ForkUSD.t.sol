// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Test, console} from "forge-std/Test.sol";
import "lib/forge-std/src/interfaces/IERC20.sol";

contract ForkUSDTest is Test {
    function setUp() public {}

    function testUSDTrans() public {
        uint256 amount = 3 * 10 ** 6;

        // IERC20 usdt = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        IUSDT usdt = IUSDT(0xdAC17F958D2ee523a2206206994597C13D831ec7);
        // 模拟帐户的初始额度
        address alice = address(0x6A1D110668424E0315Fe207fD22dA5420a1238d1);
        uint256 initUSDT = usdt.balanceOf(alice);
        vm.label(address(usdt), "USDT");
        // 执行转账
        vm.prank(address(0x23f4569002a5A07f0Ecf688142eEB6bcD883eeF8));
        usdt.transfer(alice, amount);
        // 检查结果
        console.log("-->> alice balance: ", IUSDT(usdt).balanceOf(alice));
        assertEq(usdt.balanceOf(alice), initUSDT + amount, "balance is error");
    }
}

interface IUSDT {
    function balanceOf(address account) external view returns (uint256);

    // IERC20 中是有返回值的，但是USDT实现合约的时候并没有返回值，执行usdt.transfer(alice, amount);会报错
    // 需要自定义(部分)interface来接收并执行usdt方法
    // function transfer(address to, uint256 amount) external returns (bool);

    // https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7#code
    function transfer(address to, uint256 amount) external;
}
