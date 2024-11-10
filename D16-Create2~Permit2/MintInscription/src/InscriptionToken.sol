// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract InscriptionToken is ERC20 {
    address _owner;

    constructor(string memory _symbol) ERC20(_symbol, _symbol) {
        _owner = msg.sender;
    }

    function mint(address account, uint256 value) external {
        require(_owner == msg.sender, "operator is not factory");
        _mint(account, value);
    }
}
