// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract esRNTToken is ERC20 {
    constructor() ERC20("esRNToken", "esRNT") {}

    // 谁有mint权限？
    function mint(address account, uint256 value) external {
        _mint(account, value);
    }

    function burn(address account, uint256 value) external {
        _burn(account, value);
    }

    
}
