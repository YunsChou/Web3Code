// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "forge-std/console.sol";

contract MultiCall {
    function multiDelegateCall(bytes[] calldata datas) public payable returns (bytes[] memory) {
        bytes[] memory results = new bytes[](datas.length);
        for (uint256 index = 0; index < datas.length; index++) {
            console.log("-->> address(this): %s", address(this));
            console.log("-->> index: %s", index);
            // 如果外部创建数组设置的length为2，但是没有设置datas[1]，则index=1时，datas[index]为空，调用会报错
            console.logBytes(datas[index]);
            (bool succ, bytes memory result) = address(this).delegatecall(datas[index]);
            require(succ, "delegatecall fail");
            results[index] = result;
        }

        return results;
    }

    function multiCall(address[] calldata targets, bytes[] calldata datas) public returns (bytes[] memory) {
        require(targets.length == datas.length, "targets.length != data.length");
        bytes[] memory results = new bytes[](datas.length);
        for (uint256 index = 0; index < targets.length; index++) {
            (bool succ, bytes memory result) = targets[index].call(datas[index]);
            require(succ, "multiCall fail");
            results[index] = result;
        }

        return results;
    }
}
