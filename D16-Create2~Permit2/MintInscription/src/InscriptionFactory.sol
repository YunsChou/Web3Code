// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./InscriptionToken.sol";

contract InscriptionFactory {
    struct TokenInfo {
        uint256 totoalAmount;
        uint256 perMintAmount;
        uint256 hadMintAmount;
    }

    mapping(address => TokenInfo) public tokenInfos;

    function deployInscription(string memory _symbol, uint256 _totalSupply, uint256 _perMint)
        external
        returns (address)
    {
        InscriptionToken iToken = new InscriptionToken(_symbol);

        tokenInfos[address(iToken)] =
            TokenInfo({totoalAmount: _totalSupply, perMintAmount: _perMint, hadMintAmount: uint256(0)});

        return address(iToken);
    }

    function mintInscription(address tokenAddr) external {
        require(tokenAddr != address(0), "token is 0x");
        tokenInfos[tokenAddr].hadMintAmount += tokenInfos[tokenAddr].perMintAmount; // 已铸币数量变化
        TokenInfo memory info = tokenInfos[tokenAddr];
        require(info.hadMintAmount < info.totoalAmount, "mint more than totalSupply"); // 必须低于总量
        InscriptionToken(tokenAddr).mint(msg.sender, info.perMintAmount);
    }
}
