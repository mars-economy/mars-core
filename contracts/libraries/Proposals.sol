// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Market.sol";

library Proposals {
    enum Vote {YES, NO, ABSTAIN}
    enum ProposalStatus {IN_PROGRESS, APPROVED, DECLINED}
    enum ProposalType {CREATE_MARKET, ADD_ORACLE, REMOVE_ORACLE, CHANGE_OUTCOME, CHANGE_CONTRACT, CHANGE_VALUE}

    struct Proposal {
        // mapping(uint => ProposalInfo) info;
        ProposalInfo[] info;
        mapping(uint256 => CreateMarketProposal) createMarketProposal; //uuid
        mapping(uint256 => AddOracleProposal) addOracleProposal; //uuid
        mapping(uint256 => ChangeOutcomeProposal) changeOutcomeProposal; //address
        mapping(uint256 => RemoveOracleProposal) removeOracleProposal; //uuid
        // mapping(address => RemoveOracleProposal) changeValueProposal;
        // mapping(address => RemoveOracleProposal) changeContractProposal;

        // address[] createMarketHistoric;
        // address[] addOracleProposal;

        uint256[] historic;
        uint256 count;
    }

    struct ProposalInfo {
        ProposalType proposalType;
        uint256 started; //time when proposal was created
        uint256 totalInfluence;
        ProposalStatus result;
    }

    struct Voting {
        uint256 approvalsInfluence;
        uint256 againstInfluence;
        uint256 abstainInfluence;
    }

    struct CreateMarketProposal {
        bytes16 milestoneUuid;
        uint8 position;
        string name;
        string description;
        Market.Outcome[] outcomes;
        address token;
        uint256 votingEnd;
        address newAddress;
        Voting voting;
        uint256 dueDate;
        uint256 startSharePrice;
        uint256 endSharePrice;
    }

    struct AddOracleProposal {
        address newOracle;
        Voting voting;
    }

    struct RemoveOracleProposal {
        address oracle;
        Voting voting;
    }

    struct ChangeOutcomeProposal {
        bytes16[] outcomes; //outcome1, outcome2, outcome3
        uint256[] outcomeInfluence; //100,    , 200     , 50 //also possible to change to mapping?
        address market;
        bool consensusReached;
        bytes16 winningOutcome;
    }

    // function addOracle(Proposal storage self, address _newOracle) internal {
    //     ProposalInfo storage prop = self.info[_newOracle];

    //     // || prop.proposalType == ProposalType.REMOVE_ORACLE
    //     require(prop.started == 0, "Oracle already added");

    //     self.count = self.count + 1;

    //     prop.started = block.timestamp;
    //     prop.proposalType = ProposalType.ADD_ORACLE;

    //     self.addOracleProposal[_newOracle].newOracle = _newOracle;
    // }

    // function removeOracle(Proposal storage self, address _oracle) internal {
    //     ProposalInfo storage prop = self.info[_oracle];

    //     require(prop.started != 0, "Oracle not yet added");

    //     self.count = self.count + 1;

    //     prop.started = block.timestamp;
    //     prop.proposalType = ProposalType.REMOVE_ORACLE;

    //     self.removeOracleProposal[_oracle].oracle = _oracle;
    // }

    // function vote(
    //     Proposal storage self,
    //     uint256 _proposal,
    //     Proposals.Vote _vote,
    //     uint256 votingPeriod,
    //     uint256 influence
    // ) internal {
    //     require(block.timestamp < self.info[_proposal].started + votingPeriod, "VOTING PERIOD HAS FINISHED");
    //     require(self.info[_proposal].started != 0, "PROPOSAL HASN'T BEEN CREATED");

    //     ProposalInfo storage prop = self.info[_proposal];

    //     if (_vote == Proposals.Vote.YES) {
    //         if (prop.proposalType == Proposals.ProposalType.CREATE_MARKET) {
    //             self.createMarketProposal[_proposal].voting.approvalsInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.ADD_ORACLE) {
    //             self.addOracleProposal[_proposal].voting.approvalsInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.REMOVE_ORACLE) {
    //             self.removeOracleProposal[_proposal].voting.approvalsInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_VALUE) {
    //             // self.changeValueProposal[_proposal].voting.approvalsInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_CONTRACT) {
    //             // self.changeContractProposal[_proposal].voting.approvalsInfluence += influence;
    //         }
    //     }

    //     if (_vote == Proposals.Vote.NO) {
    //         if (prop.proposalType == Proposals.ProposalType.CREATE_MARKET) {
    //             self.createMarketProposal[_proposal].voting.againstInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.ADD_ORACLE) {
    //             self.addOracleProposal[_proposal].voting.againstInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.REMOVE_ORACLE) {
    //             self.removeOracleProposal[_proposal].voting.againstInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_VALUE) {
    //             // self.changeValueProposal[_proposal].voting.againstInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_CONTRACT) {
    //             // self.changeContractProposal[_proposal].voting.againstInfluence += influence;
    //         }
    //     }

    //     if (_vote == Proposals.Vote.ABSTAIN) {
    //         if (prop.proposalType == Proposals.ProposalType.CREATE_MARKET) {
    //             self.createMarketProposal[_proposal].voting.abstainInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.ADD_ORACLE) {
    //             self.addOracleProposal[_proposal].voting.abstainInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.REMOVE_ORACLE) {
    //             self.removeOracleProposal[_proposal].voting.abstainInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_VALUE) {
    //             // self.changeValueProposal[_proposal].voting.abstainInfluence += influence;
    //         } else if (prop.proposalType == Proposals.ProposalType.CHANGE_CONTRACT) {
    //             // self.changeContractProposal[_proposal].voting.abstainInfluence += influence;
    //         }
    //     }

    //     prop.totalInfluence += influence;
    // }

    // function createMarket(
    //     Proposal storage self,
    //     address _proposalUuid,
    //     Market.Outcome[] calldata _outcomes,
    //     address _purchaseToken,
    //     uint256 _votingEnd
    // ) internal {
    //     ProposalInfo storage prop = self.info[_proposalUuid];

    //     self.count = self.count + 1;

    //     require(prop.started == 0, "NAME/ADDRESS ALREADY TAKEN");

    //     prop.started = block.timestamp;
    //     prop.proposalType = Proposals.ProposalType.CREATE_MARKET;

    //     CreateMarketProposal storage marketProposal = self.createMarketProposal[_proposalUuid];

    //     for (uint i = 0; i < _outcomes.length; i++) // FIXME: calldata -> storage
    //         marketProposal.outcomes.push(_outcomes[i]);

    //     marketProposal.token = _purchaseToken;
    //     marketProposal.votingEnd = _votingEnd;
    // }

    // function createMarketResult(Proposal storage self, address _proposal, uint256 quorum, uint256 threshold) internal returns (ProposalStatus) {
    //     if (
    //         (self.info[_proposal].totalInfluence != 0) &&
    //         ((100 *
    //             (self.createMarketProposal[_proposal].voting.approvalsInfluence +
    //                 self.createMarketProposal[_proposal].voting.againstInfluence +
    //                 self.createMarketProposal[_proposal].voting.abstainInfluence)) /
    //             self.info[_proposal].totalInfluence <
    //             quorum)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     } else if (
    //         (self.createMarketProposal[_proposal].voting.approvalsInfluence +
    //             self.createMarketProposal[_proposal].voting.againstInfluence) !=
    //         0 &&
    //         ((100 * self.createMarketProposal[_proposal].voting.approvalsInfluence) /
    //             (self.createMarketProposal[_proposal].voting.approvalsInfluence +
    //                 self.createMarketProposal[_proposal].voting.againstInfluence) >
    //             threshold)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.APPROVED;
    //     } else {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     }
    //     return self.info[_proposal].result;
    // }

    // function addOracleResult(Proposal storage self, address _proposal, uint256 quorum, uint256 threshold) internal returns (ProposalStatus) {
    //     if (
    //         (self.info[_proposal].totalInfluence != 0) &&
    //         ((100 *
    //             (self.addOracleProposal[_proposal].voting.approvalsInfluence +
    //                 self.addOracleProposal[_proposal].voting.againstInfluence +
    //                 self.addOracleProposal[_proposal].voting.abstainInfluence)) /
    //             self.info[_proposal].totalInfluence <
    //             quorum)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     } else if (
    //         (self.addOracleProposal[_proposal].voting.approvalsInfluence +
    //             self.addOracleProposal[_proposal].voting.againstInfluence) !=
    //         0 &&
    //         ((100 * self.addOracleProposal[_proposal].voting.approvalsInfluence) /
    //             (self.addOracleProposal[_proposal].voting.approvalsInfluence +
    //                 self.addOracleProposal[_proposal].voting.againstInfluence) >
    //             threshold)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.APPROVED;
    //     } else {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     }
    //     return self.info[_proposal].result;
    // }

    // function removeOracleResult(Proposal storage self, address _proposal, uint256 quorum, uint256 threshold) internal returns (ProposalStatus) {
    //     if (
    //         (self.info[_proposal].totalInfluence != 0) &&
    //         ((100 *
    //             (self.removeOracleProposal[_proposal].voting.approvalsInfluence +
    //                 self.removeOracleProposal[_proposal].voting.againstInfluence +
    //                 self.removeOracleProposal[_proposal].voting.abstainInfluence)) /
    //             self.info[_proposal].totalInfluence <
    //             quorum)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     } else if (
    //         (self.removeOracleProposal[_proposal].voting.approvalsInfluence +
    //             self.removeOracleProposal[_proposal].voting.againstInfluence) !=
    //         0 &&
    //         ((100 * self.removeOracleProposal[_proposal].voting.approvalsInfluence) /
    //             (self.removeOracleProposal[_proposal].voting.approvalsInfluence +
    //                 self.removeOracleProposal[_proposal].voting.againstInfluence) >
    //             threshold)
    //     ) {
    //         self.info[_proposal].result = ProposalStatus.APPROVED;
    //     } else {
    //         self.info[_proposal].result = ProposalStatus.DECLINED;
    //     }
    //     return self.info[_proposal].result;
    // }

    function changeOutcomeResult(Proposal storage self, uint256 _index) internal returns (ProposalStatus, uint256) {
        uint256 valueMax;
        uint256 indexMax;

        //TODO: add quorum

        for (uint256 i = 0; i < self.changeOutcomeProposal[_index].outcomes.length; i++)
            if (valueMax < self.changeOutcomeProposal[_index].outcomeInfluence[i]) {
                valueMax = self.changeOutcomeProposal[_index].outcomeInfluence[i];
                indexMax = i;
            }

        self.info[_index].result = ProposalStatus.APPROVED;
        self.historic.push(_index);

        return (ProposalStatus.APPROVED, indexMax);
    }

    function voteForOutcome(
        Proposal storage self,
        uint256 _proposal,
        uint256 _index,
        uint256 influence,
        uint256 votingPeriod
    ) internal {
        require(self.info[_proposal].started != 0, "PROPOSAL HASN'T BEEN CREATED");
        require(block.timestamp < self.info[_proposal].started + votingPeriod, "VOTING PERIOD HAS FINISHED");
        require(_index < self.changeOutcomeProposal[_proposal].outcomes.length, "INVALID INDEX");

        self.changeOutcomeProposal[_proposal].outcomeInfluence[_index] =
            self.changeOutcomeProposal[_proposal].outcomeInfluence[_index] +
            influence;

        self.info[_proposal].totalInfluence += influence;
    }

    function changeOutcome(
        Proposal storage self,
        address _predictionMarket,
        bytes16[] memory _outcomes,
        bool _consensusReached
    ) internal {
        // and not equal to zero
        // require(self.createMarketProposal[_predictionMarket].votingEnd < block.timestamp, "VOTING PERIOD HASN'T FINISHED");

        ProposalInfo memory prop; // = self.info[_predictionMarket];

        prop.started = block.timestamp;

        prop.proposalType = ProposalType.CHANGE_OUTCOME;

        self.changeOutcomeProposal[self.count].outcomes = _outcomes;
        self.changeOutcomeProposal[self.count].outcomeInfluence = new uint256[](_outcomes.length);
        self.changeOutcomeProposal[self.count].market = _predictionMarket;
        self.changeOutcomeProposal[self.count].consensusReached = _consensusReached;
        self.count = self.count + 1;

        self.info.push(prop);
    }
}
