// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/ProposalTypes.sol";

interface IMarsGovernance {
    function changeOutcome(address _predictionMarket, bytes16[] memory _outcomes) external;

    function addOracle(address _newOracle) external;

    function removeOracle(address _oracle) external;

    function createMarket(
        address _proposalUuid,
        bytes16 _milestoneUuid,
        uint8 _position,
        string memory _name,
        string memory _description,
        bytes16[] memory _outcomes,
        address _purchaseToken,
        uint256 _votingEnd
    ) external;

    function voteForOutcome(address _proposal, uint256 _index) external;

    function vote(address _proposal, ProposalTypes.Vote _vote) external;

    function finishVote(address _proposal) external;

    function getProposalState(address _proposal) external view returns (ProposalTypes.ProposalState memory);

    function getChangeOutcomeState(address _proposal) external view returns (ProposalTypes.ChangeOutcomeProposal memory);

    function getProposalResult(address _proposal) external view returns (ProposalTypes.ProposalStatus);

    function setFactory(address _marsFactory) external;

    function setSettlement(address _marsSettlement) external;
}
