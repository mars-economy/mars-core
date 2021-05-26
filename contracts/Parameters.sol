// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./interfaces/IParameters.sol";

contract Parameters is IParameters, Initializable, OwnableUpgradeable {
    address receiver; //wallet that receives protocol fee

    uint256 protocolFee;
    uint256 oracleFee;
    uint256 divisor;

    uint256 oracleSettlementPeriod;
    uint256 disputePeriod;
    uint256 votingPeriod;

    uint256 oracleAcceptanceAmount;
    uint256 proposalSubmitPrice;
    uint256 disputeFeeAmount;
    uint256 quorum;

    function initialize(
        address _receiver,
        uint256 _protocolFee,
        uint256 _oracleFee,
        uint256 _divisor,
        uint256 _oracleSettlementPeriod,
        uint256 _disputePeriod,
        uint256 _votingPeriod,
        uint256 _oracleAcceptanceAmount,
        uint256 _disputeFeeAmount,
        uint256 _proposalSubmitPrice,
        uint256 _quorum
    ) external initializer {
        __Ownable_init();

        receiver = _receiver;
        protocolFee = _protocolFee;
        oracleFee = _oracleFee;
        divisor = _divisor;

        oracleSettlementPeriod = _oracleSettlementPeriod;
        disputePeriod = _disputePeriod;
        votingPeriod = _votingPeriod;

        oracleAcceptanceAmount = oracleAcceptanceAmount;
        disputeFeeAmount = disputeFeeAmount;
        proposalSubmitPrice = proposalSubmitPrice;
        quorum = _quorum;
    }

    function getReceiver() external view override returns (address) {
        return receiver;
    }

    function getProtocolFee() external view override returns (uint256) {
        return protocolFee;
    }

    function getOracleFee() external view override returns (uint256) {
        return oracleFee;
    }

    function getDivisor() external view override returns (uint256) {
        return divisor;
    }

    function getOracleSettlementPeriod() external view override returns (uint256) {
        return oracleSettlementPeriod;
    }

    function getDisputePeriod() external view override returns (uint256) {
        return disputePeriod;
    }

    function getVotingPeriod() external view override returns (uint256) {
        return votingPeriod;
    }

    function getOracleAcceptanceAmount() external view override returns (uint256) {
        return oracleAcceptanceAmount;
    }

    function getDisputeFeeAmount() external view override returns (uint256) {
        return disputeFeeAmount;
    }

    function getProposalSubmitPrice() external view override returns (uint256) {
        return proposalSubmitPrice;
    }

    function getQuorum() external view override returns (uint256) {
        return quorum;
    }

    function setReceiver(address _newValue) external override onlyOwner {
        receiver = _newValue;
    }

    function setProtocolFee(uint256 _newValue) external override onlyOwner {
        protocolFee = _newValue;
    }

    function setOracleFee(uint256 _newValue) external override onlyOwner {
        oracleFee = _newValue;
    }

    function setDivisor(uint256 _newValue) external override onlyOwner {
        divisor = _newValue;
    }

    function setOracleSettlementPeriod(uint256 _newValue) external override onlyOwner {
        oracleSettlementPeriod = _newValue;
    }

    function setDisputePeriod(uint256 _newValue) external override onlyOwner {
        disputePeriod = _newValue;
    }

    function setVotingPeriod(uint256 _newValue) external override onlyOwner {
        votingPeriod = _newValue;
    }

    function setOracleAcceptanceAmount(uint256 _newValue) external override onlyOwner {
        oracleAcceptanceAmount = _newValue;
    }

    function setDisputeFeeAmount(uint256 _newValue) external override onlyOwner {
        disputeFeeAmount = _newValue;
    }

    function setProposalSubmitPrice(uint256 _newValue) external override onlyOwner {
        proposalSubmitPrice = _newValue;
    }

    function setQuorum(uint256 _newValue) external override onlyOwner {
        quorum = _newValue;
    }
}
