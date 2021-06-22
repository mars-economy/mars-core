// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../libraries/Proposals.sol";

interface IMarsGovernance {
    function getOutcomes(uint256 _index) external view returns (Proposals.ProposalInfo memory, Proposals.ChangeOutcomeProposal memory);

    function changeOutcome(
        address _predictionMarket,
        bytes16[] calldata _outcomes,
        bool _consensusReached
    ) external;

    function voteForOutcome(uint256 _proposal, uint256 _index) external;

    function finishVote(uint256 _proposal) external;

    function iHaveVoted() external view returns (uint256[] memory);

    function haveIVoted(uint256 i) external view returns (bool);
}
