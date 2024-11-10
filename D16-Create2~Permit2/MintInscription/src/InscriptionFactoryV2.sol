// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import "./InscriptionToken.sol";

contract InscriptionFactoryV2 {
    address public _owner;

    struct TokenInfo {
        uint256 totoalAmount;
        uint256 perMintAmount;
        uint256 hadMintAmount;
        uint256 perMintPrice;
    }

    mapping(address => TokenInfo) public tokenInfos;

    constructor() {
        _owner = msg.sender;
    }

    function deployInscription(string memory _symbol, uint256 _totalSupply, uint256 _perMint, uint256 _price)
        external
        returns (address)
    {
        InscriptionToken iToken = new InscriptionToken(_symbol);

        tokenInfos[address(iToken)] = TokenInfo({
            totoalAmount: _totalSupply,
            perMintAmount: _perMint,
            hadMintAmount: uint256(0),
            perMintPrice: _price
        });

        return address(iToken);
    }

    function mintInscription(address tokenAddr) external payable {
        require(tokenAddr != address(0), "token is 0x");
        tokenInfos[tokenAddr].hadMintAmount += tokenInfos[tokenAddr].perMintAmount; // 已铸币数量变化
        TokenInfo memory info = tokenInfos[tokenAddr];
        require(info.hadMintAmount < info.totoalAmount, "mint more than totalSupply"); // 必须低于总量
        require(msg.value < info.perMintAmount * info.perMintPrice, "you pay is not enought"); // 付费不能低于 token数量 * 单价
        InscriptionToken(tokenAddr).mint(msg.sender, info.perMintAmount);
    }

    function withdraw() external {
        require(_owner == msg.sender, "you are not owner");
        payable(_owner).transfer(address(this).balance);
    }
}
