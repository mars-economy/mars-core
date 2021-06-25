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

import "hardhat/console.sol"; //TODO: REMOVE

import "./libraries/Market.sol";

contract Register is IRegister, Initializable, OwnableUpgradeable {
    CategoryInfo[] categories;
    MilestoneInfo[] milestones;
    PredictionInfo[] predictionMarkets;
    OutcomeInfo[] outcomes;

    Settlement settlement;
    Parameters parameters;

    mapping(bytes16 => uint256) public slot;
    mapping(address => uint256) public marketSlot;

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
    ) external override onlyOwner {
        CategoryInfo memory category;
        category.id = uuid;
        category.position = position;
        category.name = name;
        category.description = description;

        if (slot[uuid] != 0) {
            categories[slot[uuid] - 1] = category;
        } else {
            categories.push(category);
            slot[uuid] = categories.length;
        }
        emit CategoryUpdatedEvent(uuid, position, name, description);
    }

    function updateMilestone(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        MilestoneStatus status
    ) external override onlyOwner {
        MilestoneInfo memory milestone;
        milestone.id = uuid;
        milestone.category = categoryUuid;
        milestone.position = position;
        milestone.name = name;
        milestone.description = description;
        milestone.status = status;

        if (slot[uuid] != 0) {
            milestones[slot[uuid] - 1] = milestone;
        } else {
            milestones.push(milestone);
            slot[uuid] = milestones.length;
        }
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
    ) external override onlyOwner returns (address) {
        // require(dueDate > block.timestamp, "MARS: Invalid prediction market due date"); //FIXME:

        PredictionInfo memory market;

        market.id = addr;
        market.milestone = milestoneUuid;
        market.position = position;
        market.name = name;
        market.description = description;
        market.token = token;
        market.dueDate = dueDate;

        if (marketSlot[market.id] != 0) {
            predictionMarkets[marketSlot[market.id] - 1] = market;
        } else {
            predictionMarkets.push(market);
            marketSlot[market.id] = predictionMarkets.length;
        }

        for (uint256 i = 0; i < outcomes.length; i++) addOutcome(market.id, outcomes[i].uuid, outcomes[i].position, outcomes[i].name);
        emit PredictionMarketRegisteredEvent(milestoneUuid, position, name, description, token, dueDate, market.id);

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

        if (slot[id] != 0) {
            outcomes[slot[id] - 1] = outcome;
        } else {
            outcomes.push(outcome);
            slot[id] = outcomes.length;
        }
        emit OutcomeChangedEvent(id, prediction, position, name);
    }

    function getPredictionData(uint256 _currentTime)
        external
        view
        override
        returns (
            CategoryInfo[] memory,
            MilestoneInfo[] memory,
            PredictionInfo[] memory,
            OutcomeInfo[] memory
        )
    {
        PredictionInfo[] memory pred = new PredictionInfo[](predictionMarkets.length);
        OutcomeInfo[] memory out = new OutcomeInfo[](outcomes.length);

        for (uint256 i = 0; i < predictionMarkets.length; i++) {
            pred[i] = predictionMarkets[i];

            uint256 predictionTimeEnd = MarsPredictionMarket(pred[i].id).getPredictionTimeEnd();

            pred[i].state = calculateState(pred[i], _currentTime, predictionTimeEnd);

            pred[i].predictorsNumber = MarsPredictionMarket(pred[i].id).predictorsNumber();
            pred[i].predictionTimeEnd = predictionTimeEnd;
        }

        for (uint256 i = 0; i < outcomes.length; i++) {
            out[i] = outcomes[i];

            out[i].stakedAmount = MarsERC20OutcomeToken(MarsPredictionMarket(out[i].prediction).tokenOutcomeAddress(out[i].id))
                .totalStakedAmount();
            out[i].winning = MarsPredictionMarket(out[i].prediction).winningOutcome() == out[i].id ? 1 : 0;
        }

        return (categories, milestones, pred, out);
    }

    function calculateState(
        PredictionInfo memory pred,
        uint256 _currentTime,
        uint256 predictionTimeEnd
    ) internal view returns (PredictionMarketState) {
        uint256 oracleSettlementTimeout = parameters.getOracleSettlementPeriod();
        uint256 disputeTimeout = parameters.getDisputePeriod();

        bool reached = settlement.reachedConsensus(pred.id);
        bool startedDispute = settlement.isDisputeStarted(pred.id);

        //enum PredictionMarketState {Open, Waiting, SettlementOracles, 
        //SettlementWithConsensus, SettlementWithoutConsensus, Dispute, Voting, Closed}

        if (settlement.isFinalized(pred.id)) return PredictionMarketState.Closed;
        else if (predictionTimeEnd > _currentTime) return PredictionMarketState.Open;
        else if (predictionTimeEnd < _currentTime && _currentTime < pred.dueDate) return PredictionMarketState.Waiting;
        else if (_currentTime > pred.dueDate && _currentTime < pred.dueDate + oracleSettlementTimeout) return PredictionMarketState.SettlementOracles;
        else if (reached && !startedDispute && _currentTime > pred.dueDate + oracleSettlementTimeout) return PredictionMarketState.SettlementWithConsensus;
        else if (!reached && !startedDispute && _currentTime > pred.dueDate + oracleSettlementTimeout) return PredictionMarketState.SettlementWithoutConsensus;
        else if (reached && startedDispute) return PredictionMarketState.Dispute;
        else if (!reached && startedDispute) return PredictionMarketState.Voting;
    }
}
