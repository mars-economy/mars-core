// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IPredictionMarketFactory {

	enum MilestoneStatus {Historical, Current, Future}
	enum PredictionMarketState {Open, Settlement, Closed}

	event CategoryUpdatedEvent(bytes16 uuid, uint8 position, string name, string description);
	event MilestoneUpdatedEvent(bytes16 uuid, bytes16 categoryUuid, uint8 position, string name, string description, MilestoneStatus status);
	event PredictionMarketCreatedEvent(bytes16 milestoneUuid, uint8 position, string name, string description, address token, uint256 dueDate, address contractAddress);
	event OutcomeChangedEvent(bytes16 uuid, address predictionMarket, uint8 position, string name);

	function setGovernor(address _governor) external;

	function updateCategory(
        bytes16 uuid,
		uint8 position,
		string memory name,
		string memory description
    ) external;

	function updateMilestone(
        bytes16 uuid,
		bytes16 categoryUuid,
		uint8 position,
		string memory name,
		string memory description,
		MilestoneStatus status
    ) external;

    function createMarket(
		bytes16 milestoneUuid,
		uint8 position,
		string memory name,
		string memory description,
        address token,
        uint256 dueDate
    ) external returns (address);

    function addOutcome(
		address predictionMarket, 
		bytes16 uuid, 
		uint8 position, 
		string memory name
	) external;
}
