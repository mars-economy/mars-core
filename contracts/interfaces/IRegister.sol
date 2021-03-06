// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/Market.sol";

interface IRegister {
    enum MilestoneStatus {Historical, Current, Future}
    enum PredictionMarketState {Open, Settlement, Closed, Waiting}

    struct CategoryInfo {
        bytes16 id;
        uint256 position;
        string name;
        string description;
    }

    struct MilestoneInfo {
        bytes16 id;
        bytes16 category;
        uint256 position;
        string name;
        string description;
        MilestoneStatus status;
    }

    struct PredictionInfo {
        address id;
        bytes16 milestone;
        uint256 position;
        string name;
        string description;
        PredictionMarketState state;
        address token;
        uint256 dueDate;
        uint256 predictionTimeEnd;
        uint256 predictorsNumber;
    }

    struct OutcomeInfo {
        bytes16 id;
        address prediction;
        uint256 position;
        string name;
        uint256 stakedAmount;
        uint8 winning;
    }

    event CategoryUpdatedEvent(bytes16 uuid, uint8 position, string name, string description);

    event MilestoneUpdatedEvent(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string name,
        string description,
        MilestoneStatus status
    );
    event PredictionMarketRegisteredEvent(
        bytes16 milestoneUuid,
        uint8 position,
        string name,
        string description,
        address token,
        uint256 dueDate,
        address contractAddress
    );
    event OutcomeChangedEvent(bytes16 uuid, address predictionMarket, uint8 position, string name);

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

    function registerMarket(
        address addr,
        bytes16 milestoneUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        address token,
        uint256 dueDate,
        uint256 predictionTimeEnd,
        Market.Outcome[] calldata outcomes
    ) external returns (address);

    function getPredictionData(uint256 _currentTime)
        external
        view
        returns (
            CategoryInfo[] memory,
            MilestoneInfo[] memory,
            PredictionInfo[] memory,
            OutcomeInfo[] memory
        );
}
