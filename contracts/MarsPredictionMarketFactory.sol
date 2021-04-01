// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IAddressResolver.sol";
import "./MarsPredictionMarket.sol";

contract MarsPredictionMarketFactory is IPredictionMarketFactory {
    address public immutable addressResolver;
    mapping(address => bool) public predictionMarkets;
    address[] markets;
    address governer;

    constructor(address _addressResolver) {
        addressResolver = _addressResolver;
    }

    function createMarket(address token, uint256 timeout) external override returns (address) {
        // require(msg.sender == governer);
        require(timeout > block.timestamp, "MARS: Invalid prediction market timeout");
        MarsPredictionMarket predictionMarket = new MarsPredictionMarket(token, timeout);
        predictionMarkets[address(predictionMarket)] = true;
        markets.push(address(predictionMarket));
        return address(predictionMarket);
    }

    function addOutcome(address _predictionMarket, bytes32 _outcome) external override {
        MarsPredictionMarket(_predictionMarket).addOutcome(_outcome);
    }

    function getMarkets() external view override returns (address[] memory) {
        return markets; //graphQL will translate this to name
    }

    function setOracle(address _predictionMarket, address _oracle) external override {
        MarsPredictionMarket(_predictionMarket).setOracle(_oracle);
    }
}
