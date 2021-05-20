// SPDX-License-Identifier: MIT
// pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./MarsPredictionMarket.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import "./interfaces/IMarsGovernance.sol";
import "./interfaces/ISettlement.sol";

//TODO: linked list with active settlements, if block.timestamp > dueDate block everything
//TODO: status.Closed -> view method derived from finalized
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

        oracleAcceptanceAmount = 100_000 ether;
        disputeFeeAmount = 20_000 ether;
    }

    function registerMarket(address _predictionMarket, uint256 _dueDate) external override onlyOwner {
        marketStatus[_predictionMarket].dueDate = _dueDate;
    }

    function addOracle(address _newOracle) external override onlyOwner {
        require(staked[_newOracle] == 0, "ORACLE ADLREADY ADDED");

        staked[_newOracle] = 1;
        emit PotentialOracleEvent(_newOracle);
    }

    function find(address value) internal returns (uint256) {
        uint256 i = 0;
        while (i < oracles.length && oracles[i] != value) {
            i++;
        }
        return i;
    }

    function removeOracle(address oracle) external override onlyOwner {
        uint256 amount = staked[oracle];
        require(startedDisputes == 0, "ACTIVE DISPUTES IN PROGRESS");

        require(amount > 0, "ORACLE NOT ADDED");
        staked[oracle] = 0;

        if (amount > 1) IERC20(marsToken).transfer(oracle, amount);

        uint256 index = find(oracle);

        oracles[index] = oracles[oracles.length - 1];
        oracles.pop();
    }

    function acceptAndStake() external override {
        require(staked[msg.sender] != 0, "NOT ADDED BY GOVERNANCE");

        if (staked[msg.sender] == 1) {
            require(startedDisputes == 0, "ACTIVE DISPUTES IN PROGRESS");
            require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");
            emit OracleAcceptedEvent(msg.sender);
            oracles.push(msg.sender);
        } else if (staked[msg.sender] < oracleAcceptanceAmount)
            require(
                IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount - staked[msg.sender]),
                "FAILED TO TRANSFER AMOUNT"
            );
        else require(IERC20(marsToken).transfer(msg.sender, staked[msg.sender] - oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        staked[msg.sender] = oracleAcceptanceAmount;
    }

    function voteWinningOutcome(address _predictionMarket, bytes16 _outcome) external override {
        require(marketStatus[_predictionMarket].dueDate != 0, "Market not registered");
        require(staked[msg.sender] >= oracleAcceptanceAmount, "Only staked oracles can vote");
        require(oracleOutcome[msg.sender][_predictionMarket] == bytes16(0), "Oracle has already voted");
        require(MarsPredictionMarket(_predictionMarket).tokenOutcomeAddress(_outcome) != address(0), "Outcome not defined");

        require(block.timestamp >= marketStatus[_predictionMarket].dueDate, "Due date hasn't come yet");
        require(block.timestamp < marketStatus[_predictionMarket].dueDate + votingPeriod, "Oracle voting has ended");

        marketStatus[_predictionMarket].oraclesVoted = marketStatus[_predictionMarket].oraclesVoted + 1;

        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVotedEvent(msg.sender, _predictionMarket, _outcome);
    }

    //for mars holders, costs 100k mars tokens, can be activated only if consensus was reached
    function openDispute(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].dueDate + votingPeriod, "Still early to open dispute");
        require(
            block.timestamp < marketStatus[_predictionMarket].dueDate + votingPeriod + timeToOpenDispute,
            "Time to open dispute has passed"
        );
        require(marketStatus[_predictionMarket].finalized == false, "Prediction is finalized");
        require(marketStatus[_predictionMarket].startedDispute == false, "Dispute has started");

        require(reachedConsensus(_predictionMarket), "Consensus has not been reached");

        marketStatus[_predictionMarket].startedDispute = true;

        require(IERC20(marsToken).transferFrom(msg.sender, address(this), disputeFeeAmount), "Failed to transfer amount");

        // IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDisputes += 1;
    }

    //for all users, free of cost, can be activated only if consensus wasn't reached
    function startVoting(address _predictionMarket) external override {
        require(block.timestamp >= marketStatus[_predictionMarket].dueDate + votingPeriod, "Still early to start voting");
        require(marketStatus[_predictionMarket].finalized == false, "Prediction is finalized");
        require(marketStatus[_predictionMarket].startedDispute == false, "Dispute has started");

        require(!reachedConsensus(_predictionMarket), "Consensus has been reached");

        marketStatus[_predictionMarket].startedDispute = true;

        // IMarsGovernance(owner()).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);

        startedDisputes += 1;
    }

    function reachedConsensus(address _predictionMarket) public view returns (bool) {
        // if (marketStatus[_predictionMarket].oraclesVoted >= oracles.length) return false;

        if (oracles.length == 0 || marketStatus[_predictionMarket].oraclesVoted == 0) return false;

        for (uint256 i = 1; i < oracles.length; i++)
            if (oracleOutcome[oracles[i - 1]][_predictionMarket] != oracleOutcome[oracles[i]][_predictionMarket]) return false;

        return true;
    }

    function punishOracles(address _predictionMarket, bytes16 _trueOutcome) internal {
        for (uint256 i = 0; i < oracles.length; i++)
            if (oracleOutcome[oracles[i]][_predictionMarket] != marketStatus[_predictionMarket].winningOutcome) {
                staked[oracles[i]] = 0;

                uint256 index = find(oracles[i]);
                oracles[index] = oracles[oracles.length - 1];
                oracles.pop();
            }
        //TODO: add reward system for user that started dispute
    }

    function withdraw() external override {
        require(oracles.length > 1, "LAST ORACLE CAN'T LEAVE");
        require(startedDisputes == 0, "ACTIVE DISPUTES IN PROGRESS");
        uint256 amount = staked[msg.sender];
        require(amount > 1, "NO TOKENS TO WITHDRAW");

        staked[msg.sender] = 1;

        require(IERC20(marsToken).transfer(msg.sender, amount), "FAILED TO TRANSFER AMOUNT");

        uint256 index = find(msg.sender);
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

        punishOracles(_predictionMarket, marketStatus[_predictionMarket].winningOutcome);

        if (marketStatus[_predictionMarket].startedDispute == true) {
            startedDisputes -= 1;
            marketStatus[_predictionMarket].startedDispute = false;
        }
    }

    function finalizeOutcome(address _predictionMarket) public {
        //switch to internal?
        if (marketStatus[_predictionMarket].finalized == true) return;

        if (
            marketStatus[_predictionMarket].dueDate + votingPeriod + timeToOpenDispute < block.timestamp &&
            marketStatus[_predictionMarket].startedDispute == false &&
            reachedConsensus(_predictionMarket)
        ) {
            marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];
            marketStatus[_predictionMarket].finalized = true;

            emit OutcomeDefinedEvent(_predictionMarket, oracleOutcome[oracles[0]][_predictionMarket]);
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

    function setOracleAcceptanceAmount(uint256 _newValue) external override onlyOwner {
        oracleAcceptanceAmount = _newValue;
    }

    function setDisputeFeeAmount(uint256 _newValue) external override onlyOwner {
        disputeFeeAmount = _newValue;
    }

    function setTimeToOpenDispute(uint256 _newValue) external override onlyOwner {
        timeToOpenDispute = _newValue;
    }

    function setVotingPeriod(uint256 _newValue) external override onlyOwner {
        votingPeriod = _newValue;
    }
}
