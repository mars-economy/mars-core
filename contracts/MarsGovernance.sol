//-------------------------------------    
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;
 
 
import "./interfaces/IMarsGovernance.sol";
import "./dependencies/tokens/ERC20.sol";
import "./MarsPredictionMarketFactory.sol";
import "./libraries/ProposalTypes.sol";
import "./libraries/ProposalLogic.sol";
 
contract MarsGovernance is IMarsGovernance {
	using ProposalLogic for Proposal;
    
    struct Proposal {
    	ProposalTypes.ProposalType proposalType;
        ProposalTypes.ProposalState state;
        mapping(address => ProposalTypes.Vote) voted;
        ProposalTypes.ProposalStatus result;
    }

 
    event ProposalVoted(address user, ProposalTypes.Vote _vote, uint256 influence);
 
    MarsPredictionMarketFactory marsFactory;
    ERC20 govToken;
    address daiToken;
 
    mapping(bytes32 => Proposal) proposal;
    mapping(bytes32 => ProposalTypes.PredictionMarketProposal) predictionMarketProposals;
    mapping(bytes32 => ProposalTypes.ChangeValueProposal) changeValueProposals;
    mapping(bytes32 => ProposalTypes.ChangeContractProposal) changeContractProposals;
 
    uint256 votingPeriod = 48;
    uint256 quorum;
    uint256 threshold;
    uint256 vetoPercentage;
 
    constructor(address _token) {
        govToken = ERC20(_token);
    }
 
    // function createMarket(bytes32 _hash, bytes32[] _outcomes) external {
    //     Proposal storage prop = proposal[_hash];
 
    //     prop.state.started = block.timestamp;
    //     prop.outcomes = _outcomes;
    // }
 
    function getProposal(bytes32 _hash) external view returns (ProposalTypes.ProposalState memory) {
        return proposal[_hash].state;
    }
 
    function vote(bytes32 _proposal, ProposalTypes.Vote _vote) external {
        address user = msg.sender;
        require(proposal[_proposal].voted[user] == ProposalTypes.Vote.NONE, "You have already voted!");
 
        proposal[_proposal].voted[user] = _vote;
 
        uint256 influence = govToken.balanceOf(user);
        require(influence > 0, "No governance tokens in wallet");
 
        if (checkIfEnded(_proposal) != ProposalTypes.ProposalStatus.IN_PROGRESS) return;
 
        if (_vote == ProposalTypes.Vote.YES) {
            proposal[_proposal].state.approvalsInfluence += influence;
        } else if (_vote == ProposalTypes.Vote.NO) {
            proposal[_proposal].state.againstInfluence += influence;
        } else if (_vote == ProposalTypes.Vote.ABSTAIN) {
            proposal[_proposal].state.abstainInfluence += influence;
        } else if (_vote == ProposalTypes.Vote.NO_WITH_VETO) {
            proposal[_proposal].state.noWithVetoInfluence += influence;
            proposal[_proposal].state.againstInfluence += influence;
        }
        emit ProposalVoted(user, _vote, influence);
    }
 
    function checkIfEnded(bytes32 _proposal) public returns (ProposalTypes.ProposalStatus) {
        require(proposal[_proposal].result == ProposalTypes.ProposalStatus.IN_PROGRESS, "voting completed");
 
        if (block.timestamp > endTime(_proposal)) {
            // return finalizeProposal(_proposal);
        } else {
            return ProposalTypes.ProposalStatus.IN_PROGRESS;
        }
    }
 
    function endTime(bytes32 _proposal) public view returns (uint256) {
        return proposal[_proposal].state.started + 1 hours * votingPeriod;
    }
 
    // function finalizeProposal(bytes32 _proposal) public returns (ProposalStatus) {
    //     require(block.timestamp > endTime(_proposal), "Proposal: Period hasn't passed");
 
    //     if (
    //         (proposal[_proposal].totalInfluence != 0) && proposal[_proposal].isDeclined(quorum)
    //     ) {
    //         proposal[_proposal].result = ProposalStatus.DECLINED;
    //         return proposal[_proposal].result;
    //     }
 
    //     if (
    //         (proposal[_proposal].approvalsInfluence + proposal[_proposal].againstInfluence + proposal[_proposal].abstainInfluence) != 0 &&
    //         ((100 * proposal[_proposal].noWithVetoInfluence) /
    //             (proposal[_proposal].approvalsInfluence + proposal[_proposal].againstInfluence + proposal[_proposal].abstainInfluence) >=
    //             vetoPercentage)
    //     ) {
    //         proposal[_proposal].result = ProposalStatus.VETO;
    //     } else if (
    //         (proposal[_proposal].approvalsInfluence + proposal[_proposal].againstInfluence) != 0 &&
    //         ((100 * proposal[_proposal].approvalsInfluence) /
    //             (proposal[_proposal].approvalsInfluence + proposal[_proposal].againstInfluence) >
    //             threshold)
    //     ) {
 
    //         {
    //             MarsPredictionMarket predictionMarket = MarsPredictionMarket(marsFactory.createMarket(daiToken, block.timestamp + 1 hours * (24 * 7)));
 
    //             for (uint i = 0; i < outcomes.length; i++)
    //                 predictionMarket.addOutcome(outcomes[i]);
    //         }
 
    //         proposal[_proposal].result = ProposalStatus.APPROVED;
    //     } else {
    //         proposal[_proposal].result = ProposalStatus.DECLINED;
    //     }
 
    //     return proposal[_proposal].result;
    // }
 
    function setDaiToken(address _token) external {
        daiToken = _token;
    }
 
    function setFactory(address _marsFactory) public {
        marsFactory = MarsPredictionMarketFactory(_marsFactory);
    }
 
    // function openMarketDispute(bytes32 _hash) external {
    //     Proposal storage prop = proposal[_hash];
 
    //     prop.state.started = block.timestamp;
    //     prop.state.proposal = _proposal;
    // }
 
    // function addOrcale(bytes32 _hash, address _oracle) external {
    //     Proposal storage prop = proposal[_hash];
 
    //     prop.state.started = block.timestamp;
    //     prop.state.proposal = _proposal;
    //     prop.newOracle = _oracle;
    // }
 
    // function removeOrcale(bytes32 _hash, address _oracle) external {
    //     Proposal storage prop = proposal[_hash];
 
    //     prop.state.started = block.timestamp;
    //     prop.state.proposal = _proposal;
    //     prop.deleteOracle = _oracle;    
    // }
 
}