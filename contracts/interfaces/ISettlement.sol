// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISettlement {
    event PotentialOracleEvent(address _newOracle);
    event OracleAcceptedEvent(address _newOracle);
    event OracleVotedEvent(address indexed _oracle, address indexed _predictionMarket, bytes16 _outcome);
    event OutcomeDefinedEvent(address indexed _predictionMarket, bytes16 _outcome);

    struct MarketStatus {
        uint256 dueDate;
        uint256 oraclesVoted;
        bytes16 winningOutcome;
        bool finalized;
        bool startedDispute;
        address disputeOpenner;
        uint256 disputeStake;
        uint256 rewardForDisputeOpener;
        mapping(address => bool) correctlyVoted;
        uint256 correctlyVotedCount;
        mapping(address => bool) hasCollected;
        uint256 collected;
    }

    function registerMarket(address _predictionMarket, uint256 _dueDate) external;

    function addOracle(address _newOracle) external;

    function removeOracle(address oracle) external;

    function acceptAndStake() external;

    function voteWinningOutcome(address _predictionMarket, bytes16 _outcome) external;

    function openDispute(address _predictionMarket) external;

    function startVoting(address _predictionMarket) external;

    function withdraw() external;

    // function reachedConsensus(address _predictionMarket) public view returns (bool);

    function setWinningOutcomeByGovernance(address _predictionMarket, bytes16 _outcome) external;

    // function finalizeOutcome(address _predictionMarket) public;

    function getWinningOutcome(address _predictionMarket) external returns (bytes16);

    function getOracles() external view returns (address[] memory);

    function oracleCorrectlyVoted(address _predictionMarket, address _oracle) external returns (bool);

    function getCorrectlyVotedCount(address _market) external view returns (uint256);
}
