// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISettlement {
    event PotentialOracleEvent(address _newOracle);
    event OracleAcceptedEvent(address _newOracle, uint256 _sum);
    event OracleVotedEvent(address _oracle, address _predictionMarket, bytes16 _outcome);

    struct MarketStatus {
        bytes16[] outcomes;
        uint256 votingEnd;
        uint256 oraclesVoted;
        bytes16 winningOutcome;
        bool finalized;
        bool startedDispute;
    }

    function registerMarket(
        address _predictionMarket,
        bytes16[] memory _outcomes,
        uint256 _votingEnd
    ) external;

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
}
