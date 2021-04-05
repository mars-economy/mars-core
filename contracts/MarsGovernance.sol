//-------------------------------------
// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";
import "./Settlement.sol";

import "./libraries/ProposalTypes.sol";
import "./libraries/ProposalLogic.sol";

import "./dependencies/tokens/IERC20.sol";

contract MarsGovernance is IMarsGovernance {
    using ProposalLogic for Proposal;
    event ProposalVoted(address user, ProposalTypes.Vote _vote, uint256 influence);

    struct Proposal {
        ProposalTypes.ProposalType proposalType;
        ProposalTypes.ProposalState state;
        mapping(address => ProposalTypes.Vote) voted;
        ProposalTypes.ProposalStatus result;
    }

    IPredictionMarketFactory marsFactory;
    IERC20 govToken;
    Settlement settlement;

    mapping(address => Proposal) proposal;
    mapping(address => ProposalTypes.CreateMarketProposal) createMarketProposal;
    mapping(address => ProposalTypes.AddOracleProposal) addOracleProposal;
    mapping(address => ProposalTypes.ChangeOutcomeProposal) changeOutcomeProposal;

    uint256 votingPeriod = 48 hours;
    uint256 quorum = 20; //percentage
    uint256 threshold = 50;

    constructor(address _govToken) {
        govToken = IERC20(_govToken);
    }

    function changeOutcome(address _predictionMarket, bytes32[] memory _outcomes) external override {
        Proposal storage prop = proposal[_predictionMarket];
        prop.state.started = block.timestamp;

        //prop.result = ProposalTypes.ProposalState.IN_PROGRESS; //not sure if needed
        prop.proposalType = ProposalTypes.ProposalType.CHANGE_OUTCOME;

        changeOutcomeProposal[_predictionMarket].outcomes = _outcomes;
    }

    function addOracle(address _newOracle) external override {
        Proposal storage prop = proposal[_newOracle]; //open for discusion
        prop.state.started = block.timestamp;

        //prop.result = ProposalTypes.ProposalState.IN_PROGRESS;
        prop.proposalType = ProposalTypes.ProposalType.ADD_ORACLE;

        addOracleProposal[_newOracle].newOracle = _newOracle;
    }

    function createMarket(
        address _name,
        bytes32[] memory _outcomes,
        address _purchaseToken
    ) external override {
        Proposal storage prop = proposal[_name]; //same...
        prop.state.started = block.timestamp;

        //prop.result = ProposalTypes.ProposalState.IN_PROGRESS;
        prop.proposalType = ProposalTypes.ProposalType.CREATE_MARKET;

        createMarketProposal[_name].outcomes = _outcomes;
        createMarketProposal[_name].token = _purchaseToken;
    }

    function voteForOutcome(address _proposal, bytes32 _trueOutcome) external {
        // for (uint i = 0; i < changeOutcome)
    }

    function vote(address _proposal, ProposalTypes.Vote _vote) external {
        Proposal storage prop = proposal[_proposal];

        uint256 influence = govToken.balanceOf(msg.sender);
        require(influence > 0, "NO GOV TOKENS IN ACCOUNT");

        if (_vote == ProposalTypes.Vote.YES) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                proposal[_proposal].state.approvalsInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                proposal[_proposal].state.approvalsInfluence += influence;
            }
        }

        if (_vote == ProposalTypes.Vote.NO) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                proposal[_proposal].state.againstInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                proposal[_proposal].state.againstInfluence += influence;
            }
        }

        if (_vote == ProposalTypes.Vote.ABSTAIN) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                proposal[_proposal].state.abstainInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                proposal[_proposal].state.abstainInfluence += influence;
            }
        }

        proposal[_proposal].state.totalInfluence += influence;
    }

    function finishVote(address _proposal) external {
        Proposal storage prop = proposal[_proposal];

        require(block.timestamp > prop.state.started + votingPeriod, "VOTING PERIOD HASN'T ENDED");

        if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
            if (
                (prop.state.totalInfluence != 0) &&
                ((100 * (prop.state.approvalsInfluence + prop.state.againstInfluence + prop.state.abstainInfluence)) /
                    prop.state.totalInfluence <
                    quorum)
            ) {
                prop.result = ProposalTypes.ProposalStatus.DECLINED;
            } else if (
                (prop.state.approvalsInfluence + prop.state.againstInfluence) != 0 &&
                ((100 * prop.state.approvalsInfluence) / (prop.state.approvalsInfluence + prop.state.againstInfluence) > threshold)
            ) {
                prop.result = ProposalTypes.ProposalStatus.APPROVED;

                IPredictionMarket market =
                    IPredictionMarket(marsFactory.createMarket(createMarketProposal[_proposal].token, block.timestamp + 60 * 60 * 24 * 2));

                // for (uint i = 0; i < createMarketProposal[_proposal].outcomes; i++){
                //     market.
                // }
            } else {
                prop.result = ProposalTypes.ProposalStatus.DECLINED;
            }
        } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
            if (
                (prop.state.totalInfluence != 0) &&
                ((100 * (prop.state.approvalsInfluence + prop.state.againstInfluence + prop.state.abstainInfluence)) /
                    prop.state.totalInfluence <
                    quorum)
            ) {
                prop.result = ProposalTypes.ProposalStatus.DECLINED;
            } else if (
                (prop.state.approvalsInfluence + prop.state.againstInfluence) != 0 &&
                ((100 * prop.state.approvalsInfluence) / (prop.state.approvalsInfluence + prop.state.againstInfluence) > threshold)
            ) {
                prop.result = ProposalTypes.ProposalStatus.APPROVED;

                settlement.addOracle(addOracleProposal[_proposal].newOracle);
            } else {
                prop.result = ProposalTypes.ProposalStatus.DECLINED;
            }
        } else if (prop.proposalType == ProposalTypes.ProposalType.CHANGE_OUTCOME) {
            uint256 valueMax;
            uint256 indexMax;

            for (uint256 i = 0; i < changeOutcomeProposal[_proposal].outcomes.length; i++)
                if (valueMax < changeOutcomeProposal[_proposal].outcomeInfluence[i]) {
                    valueMax = changeOutcomeProposal[_proposal].outcomeInfluence[i];
                    indexMax = i;
                }
        }
    }

    function getProposalState(address _proposal) external view returns (ProposalTypes.ProposalState memory) {
        return proposal[_proposal].state;
    }

    function getProposalResult(address _proposal) external view returns (ProposalTypes.ProposalStatus) {
        return proposal[_proposal].result;
    }

    //maybe change to modifier?
    function checkIfEnded(address _proposal) public view returns (ProposalTypes.ProposalStatus) {
        if (block.timestamp > endTime(_proposal)) {
            return proposal[_proposal].result;
        } else {
            return ProposalTypes.ProposalStatus.IN_PROGRESS;
        }
    }

    function endTime(address _proposal) public view returns (uint256) {
        return proposal[_proposal].state.started + votingPeriod;
    }

    function setFactory(address _marsFactory) external {
        marsFactory = IPredictionMarketFactory(_marsFactory);
    }

    function setSettlement(address _marsSettlement) external {
        settlement = Settlement(_marsSettlement);
    }
}
