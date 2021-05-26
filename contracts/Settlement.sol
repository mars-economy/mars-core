// SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./dependencies/libraries/StructuredLinkedList.sol";
import "./MarsPredictionMarket.sol";
import "./Parameters.sol";
import "./interfaces/ISettlement.sol";

import "hardhat/console.sol";

contract Settlement is ISettlement, Initializable, OwnableUpgradeable {
    using StructuredLinkedList for StructuredLinkedList.List;
    StructuredLinkedList.List list;

    //uint = 1 -> added and not staked,
    //uint > 1 -> accepted and staked,
    //uint == 0 -> not added
    mapping(address => uint256) public staked; //how much a oracle has staked,
    mapping(address => mapping(address => bytes16)) public oracleOutcome; //oracle => prediction => outcome
    mapping(address => MarketStatus) public marketStatus;

    address[] oracles;
    IERC20 marsToken;
    Parameters parameters;

    function initialize(address _marsToken, address _parameters) external initializer {
        __Ownable_init();

        marsToken = IERC20(_marsToken);
        parameters = Parameters(_parameters);
    }

    function isSettlementProcess(uint256 _currentTime) internal view returns (bool) {
        uint256 _dueDate = list.getFirstDate();

        if (_dueDate == 0 || _dueDate > _currentTime) return false;
        return true;
    }

    function registerMarket(address _predictionMarket, uint256 _dueDate) external override onlyOwner {
        list.pushSorted(_dueDate, _predictionMarket);

        marketStatus[_predictionMarket].dueDate = _dueDate;
    }

    function addOracle(address _newOracle) external override onlyOwner {
        require(staked[_newOracle] == 0, "Oracle adlready added");

        staked[_newOracle] = 1;
        emit PotentialOracleEvent(_newOracle);
    }

    function findOracle(address value) internal returns (uint256) {
        uint256 i = 0;
        while (i < oracles.length && oracles[i] != value) {
            i++;
        }
        return i;
    }

    function _removeOracle(address oracle) internal {
        uint256 index = findOracle(oracle);
        oracles[index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function removeOracle(address oracle) external override onlyOwner {
        require(!isSettlementProcess(block.timestamp), "Active disputes in progress");

        uint256 amount = staked[oracle];
        require(amount > 0, "Oracle not added");
        staked[oracle] = 0;

        if (amount > 1) marsToken.transfer(oracle, amount);

        _removeOracle(oracle);
    }

    function acceptAndStake() external override {
        uint256 stakedAmount = staked[msg.sender];
        require(stakedAmount != 0, "Not added by governance");
        uint256 oracleAcceptanceAmount = parameters.getOracleAcceptanceAmount();

        if (stakedAmount == 1) {
            require(!isSettlementProcess(block.timestamp), "Active disputes in progress");
            require(marsToken.transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "Failed to transfer amount");
            emit OracleAcceptedEvent(msg.sender);
            oracles.push(msg.sender);
        } else if (stakedAmount < oracleAcceptanceAmount)
            require(marsToken.transferFrom(msg.sender, address(this), oracleAcceptanceAmount - stakedAmount), "Failed to transfer amount");
        else require(marsToken.transfer(msg.sender, stakedAmount - oracleAcceptanceAmount), "Failed to transfer amount");

        staked[msg.sender] = oracleAcceptanceAmount;
    }

    function voteWinningOutcome(address _predictionMarket, bytes16 _outcome) external override {
        uint256 dueDate = marketStatus[_predictionMarket].dueDate;
        require(dueDate != 0, "Market not registered");

        uint256 oracleAcceptanceAmount = parameters.getOracleAcceptanceAmount();
        require(staked[msg.sender] >= oracleAcceptanceAmount, "Only staked oracles can vote");
        require(oracleOutcome[msg.sender][_predictionMarket] == bytes16(0), "Oracle has already voted");

        require(MarsPredictionMarket(_predictionMarket).tokenOutcomeAddress(_outcome) != address(0), "Outcome not defined");

        uint256 votingPeriod = parameters.getVotingPeriod();
        require(block.timestamp >= dueDate, "Due date hasn't come yet");
        require(block.timestamp < dueDate + votingPeriod, "Oracle voting has ended");

        marketStatus[_predictionMarket].oraclesVoted = marketStatus[_predictionMarket].oraclesVoted + 1;

        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVotedEvent(msg.sender, _predictionMarket, _outcome);
    }

    function openDispute(address _predictionMarket) external override {
        uint256 votingPeriod = parameters.getVotingPeriod();
        uint256 disputeTimeout = parameters.getDisputePeriod();
        uint256 dueDate = marketStatus[_predictionMarket].dueDate;
        require(block.timestamp >= dueDate + votingPeriod, "Still early to open dispute");
        require(block.timestamp < dueDate + votingPeriod + disputeTimeout, "Time to open dispute has passed");
        require(marketStatus[_predictionMarket].finalized == false, "Prediction is finalized");
        require(marketStatus[_predictionMarket].startedDispute == false, "Dispute has started");

        require(_reachedConsensus(_predictionMarket), "Consensus has not been reached");

        uint256 disputeFeeAmount = parameters.getDisputeFeeAmount();
        marketStatus[_predictionMarket].startedDispute = true;
        marketStatus[_predictionMarket].disputeOpenner = msg.sender;
        marketStatus[_predictionMarket].disputeStake = disputeFeeAmount;

        require(marsToken.transferFrom(msg.sender, address(this), disputeFeeAmount), "Failed to transfer amount");

        // IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);
    }

    function startVoting(address _predictionMarket) external override {
        uint256 votingPeriod = parameters.getVotingPeriod();
        require(block.timestamp >= marketStatus[_predictionMarket].dueDate + votingPeriod, "Still early to start voting");
        require(marketStatus[_predictionMarket].finalized == false, "Prediction is finalized");
        require(marketStatus[_predictionMarket].startedDispute == false, "Dispute has started");

        require(!_reachedConsensus(_predictionMarket), "Consensus has been reached");

        marketStatus[_predictionMarket].startedDispute = true;

        // IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);
    }

    function reachedConsensus(address _predictionMarket) external view override returns (bool) {
        return _reachedConsensus(_predictionMarket);
    }

    function _reachedConsensus(address _predictionMarket) internal view returns (bool) {
        // if (marketStatus[_predictionMarket].oraclesVoted >= oracles.length) return false;

        uint256 count = marketStatus[_predictionMarket].oraclesVoted;
        if (oracles.length == 0 || count == 0) return false;

        for (uint256 i = 1; i < count; i++)
            if (oracleOutcome[oracles[i - 1]][_predictionMarket] != oracleOutcome[oracles[i]][_predictionMarket]) return false;

        return true;
    }

    function punishAndRewardOracles(address _predictionMarket, bytes16 _trueOutcome) internal {
        uint256 punished;
        address[] memory correctlyVoted = new address[](oracles.length);
        uint256 count;

        for (uint256 i = 0; i < oracles.length; i++)
            if (oracleOutcome[oracles[i]][_predictionMarket] != marketStatus[_predictionMarket].winningOutcome) {
                punished += staked[oracles[i]];
                staked[oracles[i]] = 0;

                uint256 index = findOracle(oracles[i]);
                oracles[index] = oracles[oracles.length - 1];
                oracles.pop();
            } else {
                correctlyVoted[count] = oracles[i];
                count += 1;
            }

        //20% of mars tokens stay on Settlement
        punished = (punished * 8) / 10; //80%
        marketStatus[_predictionMarket].rewardForDisputeOpener = (punished * 1) / 10; //10%
        marketStatus[_predictionMarket].correctlyVotedCount = count;

        for (uint256 i = 0; i < count; i++) {
            marketStatus[_predictionMarket].correctlyVoted[correctlyVoted[i]] = true;

            marsToken.transfer(correctlyVoted[i], punished / count);

            // (x / y) == (x- (x/ y)) / (y-1)
            // punished -= punished / count;
            // count -= 1;
        }
    }

    function withdraw() external override {
        require(!isSettlementProcess(block.timestamp), "Active disputes in progress");
        require(oracles.length > 1, "Last oracle can't leave");
        uint256 amount = staked[msg.sender];
        require(amount > 1, "No tokens to withdraw");

        staked[msg.sender] = 1;

        require(marsToken.transfer(msg.sender, amount), "Failed to transfer amount");

        uint256 index = findOracle(msg.sender);
        oracles[index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function setWinningOutcomeByGovernance(address _predictionMarket, bytes16 _outcome) external override onlyOwner {
        if (marketStatus[_predictionMarket].finalized == true) {
            return;
        }

        marketStatus[_predictionMarket].winningOutcome = _outcome;
        marketStatus[_predictionMarket].finalized = true;

        emit OutcomeDefinedEvent(_predictionMarket, _outcome);

        punishAndRewardOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);

        if (marketStatus[_predictionMarket].startedDispute == true) {
            marketStatus[_predictionMarket].startedDispute = false;
        }

        rewardDisputeOpener(_predictionMarket);
        list.deleteByAddress(_predictionMarket);
    }

    function finalizeOutcome(address _predictionMarket) internal {
        if (marketStatus[_predictionMarket].finalized == true) return;

        uint256 settlementPeriod = parameters.getOracleSettlementPeriod();
        uint256 disputePeriod = parameters.getDisputePeriod();

        if (
            marketStatus[_predictionMarket].dueDate + settlementPeriod + disputePeriod < block.timestamp &&
            marketStatus[_predictionMarket].startedDispute == false &&
            _reachedConsensus(_predictionMarket)
        ) {
            marketStatus[_predictionMarket].finalized = true;
            marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];

            emit OutcomeDefinedEvent(_predictionMarket, oracleOutcome[oracles[0]][_predictionMarket]);

            marketStatus[_predictionMarket].correctlyVotedCount = oracles.length;

            for (uint256 i = 0; i < oracles.length; i++) {
                marketStatus[_predictionMarket].correctlyVoted[oracles[i]] = true;
            }

            list.deleteByAddress(_predictionMarket);
        }
    }

    function rewardDisputeOpener(address _predictionMarket) private {
        MarketStatus storage ms = marketStatus[_predictionMarket];

        if (ms.disputeOpenner != address(0)) marsToken.transfer(ms.disputeOpenner, ms.disputeStake + ms.rewardForDisputeOpener);
    }

    function getWinningOutcome(address _predictionMarket) external override returns (bytes16) {
        finalizeOutcome(_predictionMarket);
        require(marketStatus[_predictionMarket].finalized == true, "Prediction is not yet concluded");
        return marketStatus[_predictionMarket].winningOutcome;
    }

    function oracleCorrectlyVoted(address _predictionMarket, address _oracle) external override returns (bool) {
        require(marketStatus[_predictionMarket].finalized == true, "To early to collect");
        require(msg.sender == _predictionMarket && marketStatus[_predictionMarket].dueDate != 0, "Only markets can call this method");
        require(marketStatus[_predictionMarket].hasCollected[_oracle] == false, "Oracle has already colected");

        marketStatus[_predictionMarket].hasCollected[_oracle] = true;
        marketStatus[_predictionMarket].collected += 1;
        return marketStatus[_predictionMarket].correctlyVoted[_oracle];
    }

    function getOracles() external view override returns (address[] memory) {
        return oracles;
    }

    function getCorrectlyVotedCount(address _market) external view override returns (uint256) {
        return marketStatus[_market].correctlyVotedCount;
    }
}
