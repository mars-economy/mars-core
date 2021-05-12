// SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

// import "./dependencies/libraries/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "./dependencies/libraries/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./dependencies/tokens/IERC20.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";
import "./interfaces/ISettlement.sol";

import "hardhat/console.sol"; //TODO: REMOVE

contract Settlement is ISettlement, Initializable, OwnableUpgradeable {
    mapping(address => uint256) public staked; //how much a oracle has staked,
    //uint = 1 -> added and not staked,
    //uint > 1 -> accepted and staked,
    //uint == 0 -> not added

    // mapping(address => mapping(address => mapping(bytes16=>uint))) oracleOutcome;
    mapping(address => mapping(address => bytes16)) public oracleOutcome;
    //oracle => prediction => outcome
    mapping(address => MarketStatus) public marketStatus;

    uint256 oracleAcceptanceAmount;
    uint256 disputeFeeAmount;

    address[] oracles;
    address marsToken;

    uint256 public timeToOpenDispute;
    uint256 public votingPeriod;

    uint256 public startedDisputes;

    function initialize(address _marsToken) external initializer {
        __Ownable_init();

        marsToken = _marsToken;

        timeToOpenDispute = 60 * 60 * 24 * 7;
        votingPeriod = 60 * 60 * 24;

        oracleAcceptanceAmount = 1_000_000; // * 10**18;
        disputeFeeAmount = 100_000; // * 10**18;
    }

    function registerMarket(
        address _predictionMarket,
        bytes16[] memory _outcomes,
        uint256 _votingEnd
    ) external override onlyOwner {
        marketStatus[_predictionMarket].outcomes = _outcomes;
        marketStatus[_predictionMarket].votingEnd = _votingEnd;
    }

    function addOracle(address _newOracle) external override onlyOwner {
        require(staked[_newOracle] == 0, "ORACLE ADLREADY ADDED");

        staked[_newOracle] = 1;
        emit PotentialOracleEvent(msg.sender);
    }

    function find(address value) internal returns (uint256) {
        uint256 i = 0;
        while (oracles[i] != value) {
            i++;
        }
        return i;
    }

    function removeOracle(address oracle) external override onlyOwner {
        require(staked[oracle] > 0, "ORACLE NOT ADDED");

        staked[oracle] = 0;

        uint256 index = find(oracle);

        oracles[index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function acceptAndStake() external override {
        require(staked[msg.sender] == 1, "NOT ADDED BY GOVERNANCE");
        require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        oracles.push(msg.sender);
        staked[msg.sender] = oracleAcceptanceAmount;

        emit OracleAcceptedEvent(msg.sender, oracleAcceptanceAmount);
    }

    function voteWinningOutcome(address _predictionMarket, bytes16 _outcome) external override {
        require(marketStatus[_predictionMarket].votingEnd != 0, "MARKET NOT REGISTERED");
        require(staked[msg.sender] > 1, "ONLY ORACLES CAN VOTE");

        require(block.timestamp > marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED YET");
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd + votingPeriod, "VOTING PERIOD HAS ENDED");

        //TODO: check if vote is defined, another mapping?
        marketStatus[_predictionMarket].oraclesVoted = marketStatus[_predictionMarket].oraclesVoted + 1;

        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVotedEvent(msg.sender, _predictionMarket, _outcome);
    }

    //for mars holders, costs 100k mars tokens, can be activated only if consensus was reached
    function openDispute(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(block.timestamp <= marketStatus[_predictionMarket].votingEnd + 7 days, "7 days have passed");

        require(reachedConsensus(_predictionMarket), "CONSENSUS HAS BEEN REACHED");

        marketStatus[_predictionMarket].startedDispute = true;

        require(IERC20(marsToken).transferFrom(msg.sender, address(this), disputeFeeAmount), "FAILED TO TRANSFER AMOUNT");

        IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDisputes += 1;
    }

    //for all users, free of cost, can be activated only if consensus wasn't reached
    function startVoting(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(block.timestamp <= marketStatus[_predictionMarket].votingEnd + 7 days, "7 days have passed");

        require(!reachedConsensus(_predictionMarket), "CONSENSUS HAS NOT BEEN REACHED");

        marketStatus[_predictionMarket].startedDispute = true;

        IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDisputes += 1;
    }

    function reachedConsensus(address _predictionMarket) public view returns (bool) {
        if (marketStatus[_predictionMarket].oraclesVoted != oracles.length) return false;

        for (uint256 i = 1; i < oracles.length; i++) {
            if (
                oracleOutcome[oracles[i - 1]][_predictionMarket] != oracleOutcome[oracles[i]][_predictionMarket] &&
                oracleOutcome[oracles[i]][_predictionMarket] != bytes16(0)
            ) {
                return false;
            }
        }
        return true;
    }

    function punishOracles(address _predictionMarket, bytes16 _trueOutcome) internal {
        for (uint256 i = 0; i < oracles.length; i++)
            if (oracleOutcome[oracles[i]][_predictionMarket] != marketStatus[_predictionMarket].winningOutcome) {
                staked[oracles[i]] = 1;
            }
        //TODO: add reward system for user that started dispute
    }

    function withdraw() external override {
        require(oracles.length > 1, "LAST ORACLE CAN'T LEAVE");
        require(startedDisputes == 0, "ACTIVE DISPUTES IN PROGRESS");

        staked[msg.sender] = 1; //security reason
        require(IERC20(marsToken).transferFrom(address(this), msg.sender, staked[msg.sender]), "FAILED TO TRANSFER AMOUNT");
    }

    function setWinningOutcomeByGovernance(address _predictionMarket, bytes16 _outcome) external override onlyOwner {
        if (marketStatus[_predictionMarket].finalized == true) {
            return;
        }

        marketStatus[_predictionMarket].winningOutcome = _outcome;
        marketStatus[_predictionMarket].finalized = true;

        emit OutcomeDefinedEvent(_predictionMarket, _outcome);

        punishOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);

        if (marketStatus[_predictionMarket].startedDispute == true) {
            startedDisputes -= 1;
            marketStatus[_predictionMarket].startedDispute = false;
        }
    }

    function finalizeOutcome(address _predictionMarket) public {
        //switch to internal?
        if (marketStatus[_predictionMarket].finalized == true) {
            return;
        }

        if (
            marketStatus[_predictionMarket].votingEnd + votingPeriod + timeToOpenDispute < block.timestamp &&
            marketStatus[_predictionMarket].startedDispute == false &&
            marketStatus[_predictionMarket].finalized == false &&
            reachedConsensus(_predictionMarket)
        ) {
            marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];
            marketStatus[_predictionMarket].finalized = true;
            marketStatus[_predictionMarket].startedDispute = false;

            emit OutcomeDefinedEvent(_predictionMarket, oracleOutcome[oracles[0]][_predictionMarket]);

            punishOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);
            // if (marketStatus[_predictionMarket].startedDispute == true) { //not sure if needed
            //     startedDisputes -= 1;
            //     marketStatus[_predictionMarket].startedDispute = false;
            // }
        }
    }

    function getWinningOutcome(address _predictionMarket) external override returns (bytes16) {
        finalizeOutcome(_predictionMarket);

        require(marketStatus[_predictionMarket].finalized == true, "PREDICTION IS NOT YET CONCLUDED");
        return marketStatus[_predictionMarket].winningOutcome;
    }

    function getOracles() external view override returns (address[] memory) {
        return oracles;
    }
}
