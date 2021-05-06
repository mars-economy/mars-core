// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface ISettlement {
    event PotentialOracleEvent(address _newOracle);
    event OracleAcceptedEvent(address _newOracle, uint256 _sum);
    event OracleVotedEvent(address indexed _oracle, address indexed _predictionMarket, bytes16 indexed _outcome);
    event OutcomeDefined(address indexed _predictionMarket, bytes16 _outcome);

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

    // function setWinningOutcome(address _predictionMarket, bytes16 _outcome) public;

    function getWinningOutcome(address _predictionMarket) external returns (bytes16);

    function getOracles() external view returns (address[] memory);
}
