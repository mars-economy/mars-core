// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

interface IMarsGovernance {
    // function createProposal(bytes32 _proposal) external;

    // function getProposal(bytes32 _proposal) external view returns (ProposalState memory);

    // function vote(uint _index, Vote _vote) external;

    // function finalizeProposal(bytes32 _proposal) public;

    function changeOutcome(address _predictionMarket, bytes32[] memory _outcomes) external;

    function addOracle(address _newOracle) external;

    function createMarket(
        address _name,
        bytes32[] memory _outcomes,
        address _purchaseToken
    ) external;
}
