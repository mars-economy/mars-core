// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IPredictionMarketFactory {
    function createMarket(address token, uint256 timeout) external returns (address);

    function addOutcome(address _predictionMarket, bytes32 _outcome) external;

    function getMarkets() external view returns (address[] memory);

    function setOracle(address _market, address _oracle) external;
}
