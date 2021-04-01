// // SPDX-License-Identifier: GPL-3.0
// pragma solidity >=0.8.0 <0.9.0;

import "./dependencies/tokens/IERC20.sol";
import "./interfaces/IPredictionMarket.sol";

contract Settlement {
    event PotentialOracle(address _newOracle);
    event OracleAccepted(address _newOracle, uint _sum);
    event OracleVoted(address _oracle, address _predictionMarket, bytes32 _outcome);

    mapping (address => uint) public staked; //how much a oracle has staked, 
    //uint = 1 -> added and not staked, 
    //uint > 1 -> accepted and staked, 
    //uint == 0 -> not added 

    struct MarketStatus{
        uint predictionTimeout;  //used in finalization
        uint oraclesVoted;
        bytes32 winningOutcome;

        uint votingStart;
        uint votingEnd;
    }

    // mapping(address => mapping(address => mapping(bytes32=>uint))) oracleOutcome;
    mapping(address => mapping(address => bytes32)) oracleOutcome;

            //oracle => prediction => outcome
    mapping (address => MarketStatus) public marketStatus;

    uint oracleAcceptanceAmount = 1_000_000 ether;
    uint disputeFeeAmount = 100_000 ether;
    address governance;
    address[] oracles;
    address marsToken;

    function addOracle(address _newOracle) external {
        require(msg.sender == governance);
        require(staked[_newOracle] == 0);

        staked[_newOracle] = 1;
        emit PotentialOracle(msg.sender);
    } 
    
    function acceptAndStake() external {
        require(staked[msg.sender] == 1);
        require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        staked[msg.sender] = oracleAcceptanceAmount;
        oracles.push(msg.sender);
        emit OracleAccepted(msg.sender, oracleAcceptanceAmount);
    }

    function voteWinningOutcome(address _predictionMarket, bytes32 _outcome) external {
        require(staked[msg.sender] > 1, "ORACLE NOT ADDED OR ACCEPTED");
        require(block.timestamp > marketStatus[_predictionMarket].votingStart,"VOTING PERIOD HASN'T STARTED");
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd,"VOTING PERIOD HASN'T ENDED");

        oracleOutcome[msg.sender][_predictionMarket] = _outcome;
        emit OracleVoted(msg.sender, _predictionMarket, _outcome);
    }

    function finalize(address _predictionMarket) external {
        require(block.timestamp < marketStatus[_predictionMarket].votingEnd,"VOTING PERIOD HASN'T ENDED");

        //FIXME change to mappings
        for (uint i = 1; i < oracles.length; i++)
            if (oracleOutcome[oracles[i-1]][_predictionMarket] != oracleOutcome[oracles[i]][_predictionMarket]) {
                openDispute(_predictionMarket);
                return;
            }

        marketStatus[_predictionMarket].winningOutcome = oracleOutcome[oracles[0]][_predictionMarket];
        IPredictionMarket(_predictionMarket).setWinningOutcome(oracleOutcome[oracles[0]][_predictionMarket]);
    }

    function openDispute(address _predictionMarket) public {
        require(IERC20(marsToken).transferFrom(msg.sender, address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");
        //governance open dispute to change value
    }

    

    function punishOracles(address _predictionMarket, bytes32 _trueOutcome) public {
        for (uint i = 0; i < oracles.length; i++)
            if (oracleOutcome[oracles[i]][_predictionMarket] != marketStatus[_predictionMarket].winningOutcome){
                require(IERC20(marsToken).transferFrom(oracles[i], address(this), oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");
                staked[oracles[i]] = 1;
            }
    }

    // function addPredictionMarket() {
    //     require marketFactory;
    // }

    // startSettlementProcedure //24h 
    function withdraw() external {
        require(oracles.length>1);
        require(IERC20(marsToken).transferFrom(address(this), msg.sender, oracleAcceptanceAmount), "FAILED TO TRANSFER AMOUNT");

        staked[msg.sender] = 1;
    }

}