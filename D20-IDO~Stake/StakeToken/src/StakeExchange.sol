// SPDX-License-Identifier: MIT

pragma solidity ^0.8.26;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "./esRNToken.sol";

struct ExchangeInfoStruct {
    bool isExchanged;
    uint256 exchangeStartTime;
    uint256 exchangeFinishTime;
    uint256 exchangeNumber;
    uint256 hadExchangedNumber;
}

contract StakeExchange {
    esRNToken public profitToken;
    address public exchangeToken;
    mapping(address => ExchangeInfoStruct[]) public exchanges;

    constructor(address _exchangeToken) {
        profitToken = new esRNToken();
        exchangeToken = _exchangeToken;
    }

    // 生成兑换订单
    function createExchangeOrder(address user, uint256 amount) external {
        ExchangeInfoStruct memory exchangeInfo = ExchangeInfoStruct({
            isExchanged: false,
            exchangeStartTime: block.timestamp,
            exchangeFinishTime: 0,
            exchangeNumber: amount,
            hadExchangedNumber: 0
        });

        ExchangeInfoStruct[] storage exchangeInfos = exchanges[user];
        exchangeInfos.push(exchangeInfo);
    }

    // 兑换为RNT
    function exchangeToRNT(uint8[] memory indexs) external {
        require(indexs.length <= exchanges[msg.sender].length, "indexs more than list");

        uint256 exchangeAmount = 0;
        uint256 exchangeNumber = 0;
        for (uint8 i = 0; i < indexs.length; i++) {
            uint8 index = indexs[i];

            ExchangeInfoStruct memory exchangeInfo = exchanges[msg.sender][index];
            // 前端应该将已兑换的item设置为不可选（筛选出可兑换item，并根据时间排序）
            require(!exchangeInfo.isExchanged, "item has exchanged");

            exchangeAmount += checkExchangeRNTAmount(exchangeInfo);
            exchangeNumber += exchangeInfo.exchangeNumber;

            // 修改状态
            exchangeInfo.isExchanged = true;
            exchangeInfo.exchangeFinishTime = block.timestamp;
            exchangeInfo.hadExchangedNumber = exchangeAmount;
            exchangeInfo.exchangeNumber = 0;
            exchanges[msg.sender][index] = exchangeInfo;
        }

        // 兑换
        ERC20(exchangeToken).transfer(msg.sender, exchangeAmount);
        // 销毁esRNT
        // profitToken.transferFrom(msg.sender, address(this), exchangeNumber);
        profitToken.burn(msg.sender, exchangeNumber);
    }

    function checkExchangeRNTAmount(ExchangeInfoStruct memory exchangeInfo) public view returns (uint256) {
        require(!exchangeInfo.isExchanged, "has exchanged");

        uint256 holdDay = (block.timestamp - exchangeInfo.exchangeStartTime) / (24 * 60 * 60);
        uint256 exchangeRate = 0;
        if (holdDay >= 30) {
            exchangeRate = 1;
        } else {
            exchangeRate = holdDay / 30;
        }
        return exchangeRate * exchangeInfo.exchangeNumber;
    }
}
