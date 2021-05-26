// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./dependencies/libraries/InitializableAdminUpgradeabilityProxy.sol";

import "./interfaces/IRegister.sol";
import "./MarsPredictionMarket.sol";
import "./MarsERC20OutcomeToken.sol";
import "./MarsPredictionMarketFactory.sol";
import "./Settlement.sol";
import "./Parameters.sol";

import "./libraries/Market.sol";

contract Register is IRegister, Initializable, OwnableUpgradeable {
    CategoryInfo[] categories;
    MilestoneInfo[] milestones;
    PredictionInfo[] predictionMarkets;
    OutcomeInfo[] outcomes;

    Settlement settlement;
    Parameters parameters;

    mapping(bytes16 => uint256) public slot;

    function initialize(address _settlement, address _parameters) external initializer {
        __Ownable_init();

        settlement = Settlement(_settlement);
        parameters = Parameters(_parameters);
    }

    function updateCategory(
        bytes16 uuid,
        uint8 position,
        string calldata name,
        string calldata description
    ) external onlyOwner {
        CategoryInfo memory category;
        category.id = uuid;
        category.position = position;
        category.name = name;
        category.description = description;

        categories.push(category);
        slot[uuid] = categories.length - 1;

        emit CategoryUpdatedEvent(uuid, position, name, description);
    }

    function updateMilestone(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        MilestoneStatus status
    ) external onlyOwner {
        MilestoneInfo memory milestone;
        milestone.id = uuid;
        milestone.category = categoryUuid;
        milestone.position = position;
        milestone.name = name;
        milestone.description = description;
        milestone.status = status;

        milestones.push(milestone);
        slot[uuid] = milestones.length - 1;

        emit MilestoneUpdatedEvent(uuid, categoryUuid, position, name, description, status);
    }

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
    ) external onlyOwner returns (address) {
        require(dueDate > block.timestamp, "MARS: Invalid prediction market due date");

        PredictionInfo memory market;

        market.id = addr;
        market.milestone = milestoneUuid;
        market.position = position;
        market.name = name;
        market.description = description;
        market.token = token;
        market.dueDate = dueDate;

        predictionMarkets.push(market);
        emit PredictionMarketRegisteredEvent(milestoneUuid, position, name, description, token, dueDate, market.id);

        for (uint256 i = 0; i < outcomes.length; i++) addOutcome(market.id, outcomes[i].uuid, outcomes[i].position, outcomes[i].name);

        return market.id;
    }

    function addOutcome(
        address prediction,
        bytes16 id,
        uint8 position,
        string calldata name
    ) public onlyOwner {
        OutcomeInfo memory outcome;
        outcome.id = id;
        outcome.prediction = prediction;
        outcome.position = position;
        outcome.name = name;

        outcomes.push(outcome);
        slot[id] = outcomes.length - 1;

        emit OutcomeChangedEvent(id, prediction, position, name);
    }

    function getPredictionData(uint256 _currentTime)
        external
        view
        returns (
            CategoryInfo[] memory,
            MilestoneInfo[] memory,
            PredictionInfo[] memory,
            OutcomeInfo[] memory
        )
    {
        PredictionInfo[] memory pred = new PredictionInfo[](predictionMarkets.length);
        OutcomeInfo[] memory out = new OutcomeInfo[](outcomes.length);

        uint256 oracleSettlementTimeout = parameters.getOracleSettlementPeriod();
        uint256 disputeTimeout = parameters.getDisputePeriod();

        for (uint256 i = 0; i < predictionMarkets.length; i++) {
            pred[i] = predictionMarkets[i];

            uint256 predictionTimeEnd = MarsPredictionMarket(pred[i].id).getPredictionTimeEnd();

            if (
                MarsPredictionMarket(pred[i].id).winningOutcome() != bytes16(0) ||
                (pred[i].dueDate + oracleSettlementTimeout + disputeTimeout < _currentTime && settlement.reachedConsensus(pred[i].id))
            ) pred[i].state = PredictionMarketState.Closed;
            else if (predictionTimeEnd < _currentTime && _currentTime < pred[i].dueDate) pred[i].state = PredictionMarketState.Waiting;
            else if (predictionTimeEnd > _currentTime) pred[i].state = PredictionMarketState.Open;
            else pred[i].state = PredictionMarketState.Settlement;

            pred[i].predictorsNumber = MarsPredictionMarket(pred[i].id).predictorsNumber();
            pred[i].predictionTimeEnd = predictionTimeEnd;
        }

        for (uint256 i = 0; i < outcomes.length; i++) {
            out[i] = outcomes[i];

            out[i].stakedAmount = MarsERC20OutcomeToken(MarsPredictionMarket(outcomes[i].prediction).tokenOutcomeAddress(outcomes[i].id))
                .totalStakedAmount();
            out[i].winning = MarsPredictionMarket(outcomes[i].prediction).winningOutcome() == outcomes[i].id ? 1 : 0;
        }

        return (categories, milestones, pred, out);
    }
}
