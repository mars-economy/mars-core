// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/Market.sol";

interface IPredictionMarket {
    event PredictionEvent(address indexed _account, bytes16 _outcome, uint256 _amount);

    function getNumberOfOutcomes() external view returns (uint256);

    function getPredictionTimeEnd() external view returns (uint256);

    function addOutcome(
        bytes16 uuid,
        uint8 position,
        string memory name
    ) external;

    function predict(bytes16 _outcome, uint256 _amount) external;

    function getUserPredictionState(address _wallet, uint256 _currentTime) external view returns (Market.UserOutcomeInfo[] memory);

    function getReward() external;

    function setSettlement(address _newSettlement) external;

    function getTokenOutcomeAddress(bytes16 outcomeUuid) external view returns (address);

    function collectOracleFee() external;

    function collectProtocolFee() external;

    function setParameters(address _newParameters) external;

    function setPredictionTimeEnd(uint256 _newValue) external;

    function getSharePrice(uint256 _currentTime) external view returns (uint256);

    function isPredictionProfitable(
        bytes16 _outcome,
        uint256 _currentTime,
        uint256 notFee,
        uint256 feeDivisor
    ) external view returns (bool);
}
