// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/Market.sol";

interface IPredictionMarketFactory {
    event PredictionMarketCreatedEvent(address _market);

    function createMarket(
        address token,
        uint256 predictionTimeEnd,
        Market.Outcome[] calldata outcomes,
        uint256 startSharePrice,
        uint256 endSharePrice
    ) external returns (address);
}
