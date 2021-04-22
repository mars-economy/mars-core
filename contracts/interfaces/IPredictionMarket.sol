// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IPredictionMarket {
    event Prediction(address account, bytes32 outcome);

    function getNumberOfOutcomes() external view returns (uint256);

    function getPredictionTimeEnd() external view returns (uint256);

    function addOutcome(
		bytes16 uuid, 
		uint8 position, 
		string memory name
	) external;

    function getBalancingTimeStart() external view returns (uint256);

    function predict(bytes16 _outcome, uint256 _amount) external;

    function userOutcomeBalance(bytes16 _outcome) external returns (uint256);

    function getTokens() external view returns (address[] memory);

    function getReward() external;

    function setSettlement(address _newSettlement) external;
}
