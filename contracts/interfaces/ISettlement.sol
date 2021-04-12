// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface ISettlement {
    function registerMarket(
        address _predictionMarket,
        bytes32[] memory _outcomes,
        uint256 _votingEnd
    ) external;

    function addOracle(address _newOracle) external;

    function removeOracle(address oracle) external;

    function acceptAndStake() external;

    function voteWinningOutcome(address _predictionMarket, bytes32 _outcome) external;

    function openDispute(address _predictionMarket) external;

    function startVoting(address _predictionMarket) external;

    function withdraw() external;

    // function setWinningOutcome(address _predictionMarket, bytes32 _outcome) public;

    function getWinningOutcome(address _predictionMarket) external returns (bytes32);

    function getOracles() external view returns (address[] memory);
}
