// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

contract esRNToken {
    struct LockInfo {
        address user;
        uint64 startTime;
        uint256 amount;
    }

    LockInfo[] private _locks;

    constructor() {
        for (uint256 i = 0; i < 11; i++) {
            _locks.push(LockInfo(address(uint160(i + 1)), uint64(block.timestamp * 2 - i), 1e18 * (i + 1)));
            // _locks.push(LockInfo(address(uint160(i + 1)), uint64(block.timestamp + i), 1e18 * (i + 1)));
        }
    }

    function getLocks() external view returns (LockInfo[] memory) {
        return _locks;
    }
}
