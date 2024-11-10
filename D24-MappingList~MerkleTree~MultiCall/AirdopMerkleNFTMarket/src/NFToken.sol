// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract NFToken is ERC721 {
    constructor() ERC721("NFToken", "NFT") {}

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
    }
}
