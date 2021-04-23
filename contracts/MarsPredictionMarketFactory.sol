// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IAddressResolver.sol";
import "./MarsPredictionMarket.sol";

contract MarsPredictionMarketFactory is IPredictionMarketFactory {

	struct Category {
		uint8 position;
		string name;
		string description;
	}

	struct Milestone {
		bytes16 categoryUuid;
		uint8 position;
		string name;
		string description;
		MilestoneStatus status;
	}

	struct PredictionMarket {
		bytes16 milestoneUuid;
		uint8 position;
		string name;
		string description;
	}

	mapping(bytes16 => Category) public categories;
	mapping(bytes16 => Milestone) public milestones;
    mapping(address => PredictionMarket) public predictionMarkets;
	
    address public immutable addressResolver;
    address governor;

    constructor(address _addressResolver) {
        addressResolver = _addressResolver;
		governor = msg.sender;
    }
	
	function setGovernor(address _governor) external override {
        require(msg.sender == governor);
		governor = _governor;
	}
	
	function updateCategory(
        bytes16 uuid,
		uint8 position,
		string memory name,
		string memory description
    ) external override {
        require(msg.sender == governor);
		
		Category memory category;
		category.position = position;
		category.name = name;
		category.description = description;
		
		categories[uuid] = category;

		emit CategoryUpdatedEvent(uuid, position, name, description);
    }

	function updateMilestone(
        bytes16 uuid,
		bytes16 categoryUuid,
		uint8 position,
		string memory name,
		string memory description,
		MilestoneStatus status
    ) external override {
        require(msg.sender == governor);
		
		Milestone memory milestone;
		milestone.categoryUuid = categoryUuid;
		milestone.position = position;
		milestone.name = name;
		milestone.description = description;
		milestone.status = status;
		
		milestones[uuid] = milestone;

		emit MilestoneUpdatedEvent(uuid, categoryUuid, position, name, description, status);
    }

    function createMarket(
		bytes16 milestoneUuid,
		uint8 position,
		string memory name,
		string memory description,
        address token,
        uint256 dueDate
    ) external override returns (address) {
        require(msg.sender == governor);
        require(dueDate > block.timestamp, "MARS: Invalid prediction market due date");
        MarsPredictionMarket predictionMarket = new MarsPredictionMarket(token, dueDate);

		PredictionMarket memory market;
		market.milestoneUuid = milestoneUuid;
		market.position = position;
		market.name = name;
		market.description = description;

        predictionMarkets[address(predictionMarket)] = market;

		emit PredictionMarketCreatedEvent(milestoneUuid, position, name, description, token, dueDate, 
				address(predictionMarket));
		
        return address(predictionMarket);
    }

    function addOutcome(
		address predictionMarket, 
		bytes16 uuid, 
		uint8 position, 
		string memory name
	) external override {
        require(msg.sender == governor);
        MarsPredictionMarket(predictionMarket).addOutcome(uuid, position, name);
		emit OutcomeChangedEvent(uuid, predictionMarket, position, name);
    }

}
