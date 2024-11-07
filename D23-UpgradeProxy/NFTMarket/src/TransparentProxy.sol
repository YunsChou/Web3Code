// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract TransparentProxy {
    address public implementation;
    address public admin;

    constructor(address _implementation) {
        admin = msg.sender;
        implementation = _implementation;
    }

    receive() external payable {}

    fallback() external payable {
        require(msg.sender != admin, "admin is forbid");
        (bool succ,) = implementation.delegatecall(msg.data);
        require(succ, "delegatecall is fail");
    }

    function upgrade(address _implementation) external {
        require(msg.sender == admin, "not admin");
        implementation = _implementation;
    }
}
