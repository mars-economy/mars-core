library ProposalTypes {
    enum Vote {NONE, YES, NO, ABSTAIN}

    enum ProposalStatus {IN_PROGRESS, APPROVED, DECLINED}

    enum ProposalType {CREATE_MARKET, ADD_ORACLE, REMOVE_ORACLE, CHANGE_OUTCOME, CHANGE_CONTRACT, CHANGE_VALUE}

    struct ProposalState {
        uint256 approvalsInfluence;
        uint256 againstInfluence;
        uint256 abstainInfluence;
        uint256 started; //time when proposal was created
        uint256 totalInfluence;
    }

    struct CreateMarketProposal {
        address name; //or hash
        bytes32[] outcomes; //outcome1, outcome2, outcome3
        address token;
        uint256 votingEnd;
        address newAddress;
    }

    struct AddOracleProposal {
        address newOracle;
    }

    struct RemoveOracleProposal {
        address oracle;
    }

    struct ChangeOutcomeProposal {
        bytes32[] outcomes; //outcome1, outcome2, outcome3
        uint256[] outcomeInfluence; //100,    , 200     , 50 //also possible to change to mapping?
    }
}
