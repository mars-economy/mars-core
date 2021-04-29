// pragma solidity >=0.8.0 <0.9.0;

import "./dependencies/tokens/IERC20.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";
import "./interfaces/ISettlement.sol";

import "hardhat/console.sol"; //TODO: REMOVE

contract Settlement is ISettlement {
    mapping(address => uint256) public staked; //how much a oracle has staked,
    //uint = 1 -> added and not staked,
    //uint > 1 -> accepted and staked,
    //uint == 0 -> not added

    struct MarketStatus {
        bytes16[] outcomes;
        uint256 votingEnd;
        uint256 oraclesVoted;
        bytes16 winningOutcome;
        bool finalized;
    }

    // mapping(address => mapping(address => mapping(bytes16=>uint))) oracleOutcome;
    mapping(address => mapping(address => bytes16)) public oracleOutcome;
    //oracle => prediction => outcome
    mapping(address => MarketStatus) public marketStatus;

    uint256 oracleAcceptanceAmount = 1_000_000; //FIXME: add ether
    uint256 disputeFeeAmount = 100_000; //FIXME: add ether

    address governance;
    address[] oracles;
    address marsToken;

    uint256 timeToOpenDispute = 7 days;
    uint256 votingPeriod = 1 days;

    bool startedDispute;

    constructor(address _marsToken, address _governance) {
        marsToken = _marsToken;
        // governance = _governance;
        governance = msg.sender;
    }

    function registerMarket(
        address _predictionMarket,
        bytes16[] memory _outcomes,
        uint256 _votingEnd
    ) external override {
        require(msg.sender == governance, "ONLY GOVERNANCE CAN REGISTER MARKETS");

        marketStatus[_predictionMarket].outcomes = _outcomes;
        marketStatus[_predictionMarket].votingEnd = _votingEnd;
    }

    function addOracle(address _newOracle) external override {
        require(msg.sender == governance, "ONLY GOVERNANCE CAN ADD ORACLES");
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

    function removeOracle(address oracle) external override {
        require(msg.sender == governance, "ONLY GOVERNANCE CAN ADD REMOVE");
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
        require(staked[msg.sender] > 1, "YOU SHALL NOT VOTE, until you stake 1 mil tokens");
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HAS ENDED");
        // require(block.timestamp < marketStatus[_predictionMarket].votingEnd + votingPeriod, "VOTING PERIOD HASN'T ENDED YET");

        //TODO: check if vote is defined
        marketStatus[_predictionMarket].oraclesVoted = marketStatus[_predictionMarket].oraclesVoted + 1;

        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVotedEvent(msg.sender, _predictionMarket, _outcome);
    }

    //for mars holders, costs 100k mars tokens, can be activated only if consensus was reached
    function openDispute(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(block.timestamp <= marketStatus[_predictionMarket].votingEnd + 7 days, "7 days have passed");

        require(reachedConsensus(_predictionMarket), "CONSENSUS HAS BEEN REACHED");

        require(IERC20(marsToken).transferFrom(msg.sender, address(this), disputeFeeAmount), "FAILED TO TRANSFER AMOUNT");

        IMarsGovernance(governance).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDispute = true;
    }

    //for all users, free of cost, can be activated only if consensus wasn't reached
    function startVoting(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(block.timestamp <= marketStatus[_predictionMarket].votingEnd + 7 days, "7 days have passed");

        require(!reachedConsensus(_predictionMarket), "CONSENSUS HAS NOT BEEN REACHED");

        IMarsGovernance(governance).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDispute = true;
    }

    function reachedConsensus(address _predictionMarket) public view returns (bool) {
        if (marketStatus[_predictionMarket].oraclesVoted != oracles.length) return false;

        //FIXME: change to mappings
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

    // startSettlementProcedure //24h
    function withdraw() external override {
        require(oracles.length > 1, "LAST ORACLE CAN'T LEAVE");

        staked[msg.sender] = 1; //security reason
        require(IERC20(marsToken).transferFrom(address(this), msg.sender, staked[msg.sender]), "FAILED TO TRANSFER AMOUNT");
    }

    function setWinningOutcome(address _predictionMarket, bytes16 _outcome) public {
        if (marketStatus[_predictionMarket].finalized == true) {
            return;
        }

        if (msg.sender == governance) {
            marketStatus[_predictionMarket].winningOutcome = _outcome;
            marketStatus[_predictionMarket].finalized = true;
            punishOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);
        } else if (
            marketStatus[_predictionMarket].votingEnd + timeToOpenDispute < block.timestamp &&
            startedDispute == false &&
            reachedConsensus(_predictionMarket)
        ) {
            marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];
            marketStatus[_predictionMarket].finalized = true;
            punishOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);
        }
    }

    function getWinningOutcome(address _predictionMarket) external override returns (bytes16) {
        setWinningOutcome(_predictionMarket, bytes16(0));

        require(marketStatus[_predictionMarket].finalized == true, "PREDICTION IS NOT YET CONCLUDED");
        return marketStatus[_predictionMarket].winningOutcome;
    }

    function getOracles() external view override returns (address[] memory) {
        return oracles;
    }
}
