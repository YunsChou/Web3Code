// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

contract MyWallet {
    string public name;
    mapping(address => bool) private approved;
    address public owner;

    modifier auth() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    constructor(string memory _name) {
        name = _name;
        owner = msg.sender;
    }

    function transferOwnership(address _addr) public auth {
        require(_addr != address(0), "New owner is the zero address");
        require(owner != _addr, "New owner is the same as the old owner");
        owner = _addr;
    }

    function getStorageSlotOwner() public view returns (address ownerAddr) {
        assembly {
            ownerAddr := sload(2)
        }
    }

    function setStorageSlotOwner(address newOwner) public auth {
        assembly {
            sstore(2, newOwner)
        }
    }
}
