// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/Market.sol";

interface IPredictionMarketFactory {
    enum MilestoneStatus {Historical, Current, Future}
    enum PredictionMarketState {Open, Settlement, Closed}

    event CategoryUpdatedEvent(bytes16 uuid, uint8 position, string name, string description);
    event MilestoneUpdatedEvent(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string name,
        string description,
        MilestoneStatus status
    );
    event PredictionMarketCreatedEvent(
        bytes16 milestoneUuid,
        uint8 position,
        string name,
        string description,
        address token,
        uint256 dueDate,
        address contractAddress
    );
    event OutcomeChangedEvent(bytes16 uuid, address predictionMarket, uint8 position, string name);

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

    function updateCategory(
        bytes16 uuid,
        uint8 position,
        string calldata name,
        string calldata description
    ) external;

    function updateMilestone(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        MilestoneStatus status
    ) external;

    function createMarket(
        bytes16 milestoneUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        address token,
        uint256 dueDate,
        Market.Outcome[] calldata outcomes
    ) external returns (address);

    // //Obsolete
    // function addOutcome(
    //     address predictionMarket,
    //     bytes16 uuid,
    //     uint8 position,
    //     string calldata name
    // ) external;

    // function getMarkets() external view returns (address[] memory);
}
