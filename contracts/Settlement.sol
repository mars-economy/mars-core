// // SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.8.0 <0.9.0;

import "./dependencies/tokens/IERC20.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";

contract Settlement {
    event PotentialOracle(address _newOracle);
    event OracleAccepted(address _newOracle, uint256 _sum);
    event OracleVoted(address _oracle, address _predictionMarket, bytes32 _outcome);

    mapping(address => uint256) public staked; //how much a oracle has staked,
    //uint = 1 -> added and not staked,
    //uint > 1 -> accepted and staked,
    //uint == 0 -> not added

    struct MarketStatus {
        uint256 predictionTimeout; //used in finalization
        uint256 oraclesVoted;
        bytes32[] outcomes;
        bytes32 winningOutcome;
        uint256 votingStart;
        uint256 votingEnd;
    }

    // mapping(address => mapping(address => mapping(bytes32=>uint))) oracleOutcome;
    mapping(address => mapping(address => bytes32)) public oracleOutcome;
    //oracle => prediction => outcome
    mapping(address => MarketStatus) public marketStatus;

    uint256 oracleAcceptanceAmount = 1_000_000;
    uint256 disputeFeeAmount = 100_000 ether;

    address governance;
    address[] oracles;
    address marsToken;

    constructor(address _marsToken, address _governance) {
        marsToken = _marsToken;
        governance = _governance;
    }

    function addOracle(address _newOracle) external {
        require(msg.sender == governance);
        require(staked[_newOracle] == 0);

        staked[_newOracle] = 1;
        emit PotentialOracle(msg.sender);
    }

    function acceptAndStake() external {
        require(staked[msg.sender] == 1, "NOT ADDED BY GOVERNANCE");
        require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        oracles.push(msg.sender);
        staked[msg.sender] = oracleAcceptanceAmount;

        emit OracleAccepted(msg.sender, oracleAcceptanceAmount);
    }

    function voteWinningOutcome(address _predictionMarket, bytes32 _outcome) external {
        require(staked[msg.sender] > 1, "YOU SHALL NOT VOTE, until you stake 1 mil tokens");
        require(block.timestamp > marketStatus[_predictionMarket].votingStart, "VOTING PERIOD HASN'T STARTED");
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HAS ENDED");

        marketStatus[_predictionMarket].oraclesVoted = marketStatus[_predictionMarket].oraclesVoted + 1;
        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVoted(msg.sender, _predictionMarket, _outcome);
    }

    function openDispute(address _predictionMarket) public {
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(!reachedConsensus(_predictionMarket), "CONSENSUS HAS NOT BEEN REACHED");

        require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        IMarsGovernance(governance).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);
    }

    function startVoting(address _predictionMarket) public {
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd, "VOTING PERIOD HASN'T ENDED");
        require(reachedConsensus(_predictionMarket), "CONSENSUS HAS BEEN REACHED");

        IMarsGovernance(governance).changeOutcome(_predictionMarket, marketStatus[_predictionMarket].outcomes);
    }

    function reachedConsensus(address _predictionMarket) public returns (bool) {
        marketStatus[_predictionMarket].oraclesVoted == oracles.length;

        //FIXME change to mappings
        for (uint256 i = 1; i < oracles.length; i++)
            if (oracleOutcome[oracles[i - 1]][_predictionMarket] != oracleOutcome[oracles[i]][_predictionMarket]) {
                return false;
            }
        return true;
    }

    // marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];
    // IPredictionMarket(_predictionMarket).setWinningOutcome(oracleOutcome[oracles[0]][_predictionMarket]);

    function punishOracles(address _predictionMarket, bytes32 _trueOutcome) public {
        for (uint256 i = 0; i < oracles.length; i++)
            if (oracleOutcome[oracles[i]][_predictionMarket] != marketStatus[_predictionMarket].winningOutcome) {
                require(IERC20(marsToken).transferFrom(oracles[i], address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");
                staked[oracles[i]] = 1;
            }
    }

    // function addPredictionMarket() {
    //     require marketFactory;
    // }

    // startSettlementProcedure //24h
    function withdraw() external {
        require(oracles.length > 1);
        require(IERC20(marsToken).transferFrom(address(this), msg.sender, oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        staked[msg.sender] = 1;
    }

    function getOracles() external view returns (address[] memory) {
        return oracles;
    }
}
