library ProposalTypes {
    enum Vote {
        NONE, 
        YES,
        NO,
        ABSTAIN,
        NO_WITH_VETO
    }

    enum ProposalStatus {
        IN_PROGRESS,
        APPROVED,
        DECLINED,
        VETO
    }

    enum ProposalType {
    	CONTRACT,
    	VALUE,
    	PREDICTION_MARKET
    }
 
    struct ProposalState {
        uint256 approvalsInfluence;
        uint256 againstInfluence;
        uint256 abstainInfluence;
        uint256 noWithVetoInfluence;
        uint256 started; //time when proposal was created
        uint256 totalInfluence;
    }
 
    struct PredictionMarketProposal {
    	bytes32   name;
    	bytes32[] outcomes;
    }
 
    struct ChangeValueProposal {
    	bytes32   name;
    	address   target; //change name
    	uint256   value;
    }
 
    struct ChangeContractProposal {
    	bytes32 name;
    	address changeFrom;
        address changeTo;
    }
}