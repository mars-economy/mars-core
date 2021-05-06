//-------------------------------------
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";
import "./Settlement.sol";

import "./libraries/ProposalTypes.sol";
import "./libraries/ProposalLogic.sol";

import "./dependencies/tokens/IERC20.sol";

import "hardhat/console.sol"; //TODO: REMOVE

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

    mapping(address => Proposal) internal proposal;
    mapping(address => ProposalTypes.CreateMarketProposal) internal createMarketProposal;
    mapping(address => ProposalTypes.AddOracleProposal) internal addOracleProposal;
    mapping(address => ProposalTypes.ChangeOutcomeProposal) internal changeOutcomeProposal;
    mapping(address => ProposalTypes.RemoveOracleProposal) internal removeOracleProposal;

    uint256 votingPeriod = 48 hours;
    uint256 quorum = 20; //percentage
    uint256 threshold = 50;

    constructor(address _govToken) {
        govToken = IERC20(_govToken);
    }

    function changeOutcome(address _predictionMarket, bytes16[] memory _outcomes) external override {
        require(msg.sender == address(settlement), "ONLY SETTLEMENT CAN START THIS PROPOSAL");
        require(createMarketProposal[_predictionMarket].votingEnd < block.timestamp, "VOTING PERIOD HASN'T FINISHED");
        proposal[_predictionMarket].state.totalInfluence = 0; //renewing influence?

        Proposal storage prop = proposal[_predictionMarket];
        prop.state.started = block.timestamp;

        //prop.result = ProposalTypes.ProposalState.IN_PROGRESS; //not sure if needed
        prop.proposalType = ProposalTypes.ProposalType.CHANGE_OUTCOME;

        changeOutcomeProposal[_predictionMarket].outcomes = _outcomes;
        changeOutcomeProposal[_predictionMarket].outcomeInfluence = new uint256[](_outcomes.length);
    }

    function addOracle(address _newOracle) external override {
        Proposal storage prop = proposal[_newOracle];

        require(prop.state.started == 0 || prop.proposalType == ProposalTypes.ProposalType.REMOVE_ORACLE, "ORACLE ALREADY ADDED");

        prop.state.started = block.timestamp;

        prop.result = ProposalTypes.ProposalStatus.IN_PROGRESS;

        prop.proposalType = ProposalTypes.ProposalType.ADD_ORACLE;

        addOracleProposal[_newOracle].newOracle = _newOracle;
    }

    function removeOracle(address _oracle) external override {
        Proposal storage prop = proposal[_oracle];

        require(prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE, "ORACLE ALREADY DELETED OR NOT ADDED");

        prop.state.started = block.timestamp;

        prop.result = ProposalTypes.ProposalStatus.IN_PROGRESS;

        prop.proposalType = ProposalTypes.ProposalType.REMOVE_ORACLE;
        prop.state.approvalsInfluence = 0;
        prop.state.againstInfluence = 0;
        prop.state.abstainInfluence = 0;
        prop.state.totalInfluence = 0;

        addOracleProposal[_oracle].newOracle = _oracle;
    }

    function createMarket(
        address _proposalUuid,
        bytes16 _milestoneUuid,
        uint8 _position,
        string memory _name,
        string memory _description,
        bytes16[] memory _outcomes,
        address _purchaseToken,
        uint256 _votingEnd
    ) external override {
        Proposal storage prop = proposal[_proposalUuid];

        require(prop.state.started == 0, "NAME/ADDRESS ALREADY TAKEN");

        prop.state.started = block.timestamp;

        //prop.result = ProposalTypes.ProposalState.IN_PROGRESS;
        prop.proposalType = ProposalTypes.ProposalType.CREATE_MARKET;

        createMarketProposal[_proposalUuid].milestoneUuid = _milestoneUuid;
        createMarketProposal[_proposalUuid].position = _position;
        createMarketProposal[_proposalUuid].name = _name;
        createMarketProposal[_proposalUuid].description = _description;
        createMarketProposal[_proposalUuid].outcomes = _outcomes;
        createMarketProposal[_proposalUuid].token = _purchaseToken;
        createMarketProposal[_proposalUuid].votingEnd = _votingEnd;
    }

    function voteForOutcome(address _proposal, uint256 _index) external override {
        require(proposal[_proposal].state.started != 0, "PROPOSAL HASN'T BEEN CREATED");
        require(block.timestamp < proposal[_proposal].state.started + votingPeriod, "VOTING PERIOD HAS FINISHED");
        require(_index < changeOutcomeProposal[_proposal].outcomes.length, "INVALID INDEX");
        uint256 influence = govToken.balanceOf(msg.sender);
        require(influence > 0, "NO GOV TOKENS IN ACCOUNT");

        changeOutcomeProposal[_proposal].outcomeInfluence[_index] = changeOutcomeProposal[_proposal].outcomeInfluence[_index] + influence;

        proposal[_proposal].state.totalInfluence += influence;
    }

    function vote(address _proposal, ProposalTypes.Vote _vote) external override {
        require(proposal[_proposal].state.started != 0, "PROPOSAL HASN'T BEEN CREATED");
        require(block.timestamp < proposal[_proposal].state.started + votingPeriod, "VOTING PERIOD HAS FINISHED");
        uint256 influence = govToken.balanceOf(msg.sender);
        require(influence > 0, "NO GOV TOKENS IN ACCOUNT");

        Proposal storage prop = proposal[_proposal];

        if (_vote == ProposalTypes.Vote.YES) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                prop.state.approvalsInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                prop.state.approvalsInfluence += influence;
            }
        }

        if (_vote == ProposalTypes.Vote.NO) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                prop.state.againstInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                prop.state.againstInfluence += influence;
            }
        }

        if (_vote == ProposalTypes.Vote.ABSTAIN) {
            if (prop.proposalType == ProposalTypes.ProposalType.CREATE_MARKET) {
                prop.state.abstainInfluence += influence;
            } else if (prop.proposalType == ProposalTypes.ProposalType.ADD_ORACLE) {
                prop.state.abstainInfluence += influence;
            }
        }

        prop.state.totalInfluence += influence;
    }

    function finishVote(address _proposal) external override {
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

                // ((((((((((((((((()))))))))))))))))
                IPredictionMarket market =
                    IPredictionMarket(
                        marsFactory.createMarket(
                            createMarketProposal[_proposal].milestoneUuid,
                            createMarketProposal[_proposal].position,
                            createMarketProposal[_proposal].name,
                            createMarketProposal[_proposal].description,
                            createMarketProposal[_proposal].token,
                            createMarketProposal[_proposal].votingEnd
                        )
                    );

                for (uint256 i = 0; i < createMarketProposal[_proposal].outcomes.length; i++) {
                    // TODO: change to real outcome params and invoke via factory
                    market.addOutcome(createMarketProposal[_proposal].outcomes[i], 1, "");
                }

                settlement.registerMarket(
                    address(market),
                    createMarketProposal[_proposal].outcomes,
                    createMarketProposal[_proposal].votingEnd
                );
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

                // ((((((((((((((((()))))))))))))))))
                settlement.addOracle(addOracleProposal[_proposal].newOracle);
            } else {
                prop.result = ProposalTypes.ProposalStatus.DECLINED;
            }
        } else if (prop.proposalType == ProposalTypes.ProposalType.REMOVE_ORACLE) {
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

                // ((((((((((((((((()))))))))))))))))
                settlement.removeOracle(removeOracleProposal[_proposal].oracle);
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

            settlement.setWinningOutcome(_proposal, changeOutcomeProposal[_proposal].outcomes[indexMax]);
        }
    }

    function getProposalState(address _proposal) external view override returns (ProposalTypes.ProposalState memory) {
        return proposal[_proposal].state;
    }

    function getChangeOutcomeState(address _proposal) external view override returns (ProposalTypes.ChangeOutcomeProposal memory) {
        return changeOutcomeProposal[_proposal];
    }

    function getProposalResult(address _proposal) external view override returns (ProposalTypes.ProposalStatus) {
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

    function setFactory(address _marsFactory) external override {
        marsFactory = IPredictionMarketFactory(_marsFactory);
    }

    function setSettlement(address _marsSettlement) external override {
        settlement = Settlement(_marsSettlement);
    }
}
