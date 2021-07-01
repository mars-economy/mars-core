// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IPredictionMarket.sol";
import "./interfaces/IMarsGovernance.sol";
import "./interfaces/IParameters.sol";
import "./interfaces/IRegister.sol";
import "./Settlement.sol";

import "./libraries/Proposals.sol";
import "./libraries/Market.sol";

import "hardhat/console.sol"; //TODO: REMOVE
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract MarsGovernance is IMarsGovernance, Initializable {
    event Test(uint256 result);

    using Proposals for Proposals.Proposal;
    Proposals.Proposal proposals;

    IPredictionMarketFactory marsFactory;
    IParameters parameters;
    Settlement settlement;
    IRegister register;
    IERC20 govToken;

    uint256 threshold;
    //user     //proposals
    mapping(address => uint256[]) votedList; // [1,2,3,4]
    //proposal //voted
    mapping(uint256 => mapping(address => Voted)) voted; //1 -> true, 2 -> true, 5 -> false

    function initialize(address _govToken, address _parameters) external initializer {
        govToken = IERC20(_govToken);
        parameters = IParameters(_parameters);

        threshold = 50;
    }

    function getOutcomes(uint256 _index)
        external
        view
        override
        returns (Proposals.ProposalInfo memory, Proposals.ChangeOutcomeProposal memory)
    {
        Proposals.ProposalInfo memory info = proposals.info[_index];
        Proposals.ChangeOutcomeProposal memory outcomes = proposals.changeOutcomeProposal[_index];

        return (info, outcomes);
    }

    function changeOutcome(
        address _predictionMarket,
        bytes16[] calldata _outcomes,
        bool _consensusReached
    ) external override {
        // require(msg.sender == address(settlement), "ONLY SETTLEMENT CAN START THIS PROPOSAL");

        proposals.changeOutcome(_predictionMarket, _outcomes, _consensusReached);
    }

    function voteForOutcome(uint256 _proposal, uint256 _index) external override {
        require(voted[_proposal][msg.sender].voted == false, "Already voted");
        
        voted[_proposal][msg.sender].voted = true;
        voted[_proposal][msg.sender].outcomeIndex = _index;

        votedList[msg.sender].push(_proposal);

        uint256 influence = govToken.balanceOf(msg.sender);
        require(influence > 0, "No gov tokens in account");
        uint256 _votingPeriod = parameters.getVotingPeriod();

        proposals.voteForOutcome(_proposal, _index, influence, _votingPeriod);
    }

    function finishVote(uint256 _proposal) external override {
        uint256 _votingPeriod = parameters.getVotingPeriod();
        require(block.timestamp > proposals.info[_proposal].started + _votingPeriod, "VOTING PERIOD HASN'T ENDED");
        //TODO: check if finished

        Proposals.ProposalType tmp = proposals.info[_proposal].proposalType;

        // uint256 _threshold = parameters.getThreshold(); //FIXME: add to parameters
        uint256 _quorum = parameters.getQuorum();

        if (tmp == Proposals.ProposalType.CREATE_MARKET) {
            // if (proposals.createMarketResult(_proposal, _quorum, threshold) == Proposals.ProposalStatus.APPROVED) {
            //     emit Test(200);
            //     _createMarket(_proposal);
            //     return;
            // }
        } else if (tmp == Proposals.ProposalType.ADD_ORACLE) {
            // if (proposals.addOracleResult(_proposal, _quorum, threshold) == Proposals.ProposalStatus.APPROVED) {
            //     emit Test(201);
            //     // settlement.addOracle(self.addOracleProposal[_proposal].newOracle);
            //     return;
            // }
        } else if (tmp == Proposals.ProposalType.REMOVE_ORACLE) {
            // if (proposals.removeOracleResult(_proposal, _quorum, threshold) == Proposals.ProposalStatus.APPROVED) {
            //     emit Test(202);
            //     settlement.removeOracle(proposals.removeOracleProposal[_proposal].oracle);
            //     return;
            // }
        } else if (tmp == Proposals.ProposalType.CHANGE_OUTCOME) {
            (Proposals.ProposalStatus status, uint256 indexMax) = proposals.changeOutcomeResult(_proposal);
            if (status == Proposals.ProposalStatus.APPROVED) {
                proposals.changeOutcomeProposal[_proposal].winningOutcome = proposals.changeOutcomeProposal[_proposal].outcomes[indexMax];
                emit Test(indexMax);
                // settlement.setWinningOutcome(_proposal, proposals.changeOutcomeProposal[_proposal].outcomes[indexMax]);
                return;
            }
        } else if (tmp == Proposals.ProposalType.CHANGE_CONTRACT) {} else if (tmp == Proposals.ProposalType.CHANGE_VALUE) {}
        emit Test(100);
    }

    function getOutcomeStatus(bool historic, address me) external view returns (OutcomeStatus[] memory) {
        Proposals.ProposalInfo[] memory props;
        OutcomeStatus[] memory reply;

        if (historic == true) {
            props = new Proposals.ProposalInfo[](proposals.historic.length);
            reply = new OutcomeStatus[](proposals.historic.length);

            for (uint256 i = 0; i < proposals.historic.length; i++) {
                props[i] = proposals.info[i];
            }
        } else { //TODO: need to review this... might be bug prone
            props = new Proposals.ProposalInfo[](proposals.info.length - proposals.historic.length);
            reply = new OutcomeStatus[](proposals.info.length - proposals.historic.length);
            uint256 iter;

            if(reply.length > 0)
                for (uint256 i = 1; i < proposals.historic.length; i++) {
                    for (uint256 j = proposals.historic[i-1]; i < proposals.historic[i]; j++) {
                        props[iter] = proposals.info[j];
                        iter++;
                    }
                }

            if(reply.length > 1)
                for (uint256 i = proposals.historic[proposals.historic.length-1]; i < proposals.info.length; i++) {
                    props[iter] = proposals.info[i];
                    iter++;
                }
        }

        uint256 _votingPeriod = parameters.getVotingPeriod();
        uint256 DMTSupply = govToken.totalSupply();

        if(reply.length > 0)
            for (uint256 i = 0; i < props.length; i++) {
                reply[i].consensusReached = proposals.changeOutcomeProposal[i].consensusReached;
                reply[i].market = proposals.changeOutcomeProposal[i].market;
                reply[i].endDate = proposals.info[i].started + _votingPeriod;
                reply[i].decision = proposals.changeOutcomeProposal[i].winningOutcome;
                reply[i].totalSupply = proposals.info[i].totalInfluence;
                if (DMTSupply != 0) reply[i].quorumPercentage = (reply[i].totalSupply * 100) / DMTSupply;
                reply[i].quorumReached = reply[i].quorumPercentage >= 50;
                reply[i].voted = _percentages(proposals.changeOutcomeProposal[i].outcomeInfluence, proposals.changeOutcomeProposal[i].outcomes, i, reply[i].decision, me);
                reply[i].proposalId = i;
            }

        return reply;
    }

    function _percentages(uint256[] memory influences, bytes16[] memory id, uint256 proposal, bytes16 winningOutcome, address _addr) internal view returns (OutcomeVoting[] memory) {
        uint256 biggestElement;
        OutcomeVoting[] memory stats = new OutcomeVoting[](influences.length);

        for (uint256 i = 0; i < influences.length; i++) {
            if (influences[i] > biggestElement) biggestElement = influences[i];
        }

        if (biggestElement != 0) 
            for (uint256 i = 0; i < influences.length; i++) {
                stats[i].percentage = (influences[i] * 100) / biggestElement;
                stats[i].outcome = id[i];
                stats[i].voted = _haveIVoted(proposal, _addr).outcomeIndex == i;
                stats[i].isWinningOutcome = stats[i].outcome == winningOutcome;
            }
        
        return stats;
    }

    function iHaveVoted() external view override returns (uint256[] memory) {
        return votedList[msg.sender];
    }

    function haveIVoted(uint256 i) external view override returns (Voted memory) {
        return _haveIVoted(i, msg.sender);
    }
    
    function _haveIVoted(uint256 i, address addr) internal view returns (Voted memory) {
        return voted[i][addr];
    }
}
