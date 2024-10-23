// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./ERC721Coin.sol";

contract ERC721NFT is ERC721Coin {
    address public _owner;

    constructor(string memory name_, string memory symbol_) ERC721Coin(name_, symbol_) {
       _owner = msg.sender;
    }

    function safeMint(address to, uint256 tokenId, string memory baseURI_) external {
        require(msg.sender == _owner, "msg.sender is not owner");
        _mint(to, tokenId);
         baseURI = baseURI_;
    }
}