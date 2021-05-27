// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IParameters {
    function getReceiver() external view returns (address);

    function getProtocolFee() external view returns (uint256);

    function getOracleFee() external view returns (uint256);

    function getDivisor() external view returns (uint256);

    function getOracleSettlementPeriod() external view returns (uint256);

    function getDisputePeriod() external view returns (uint256);

    function getVotingPeriod() external view returns (uint256);

    function getOracleAcceptanceAmount() external view returns (uint256);

    function getDisputeFeeAmount() external view returns (uint256);

    function getProposalSubmitPrice() external view returns (uint256);

    function getQuorum() external view returns (uint256);

    function setReceiver(address _newValue) external;

    function setProtocolFee(uint256 _newValue) external;

    function setOracleFee(uint256 _newValue) external;

    function setDivisor(uint256 _newValue) external;

    function setOracleSettlementPeriod(uint256 _newValue) external;

    function setDisputePeriod(uint256 _newValue) external;

    function setVotingPeriod(uint256 _newValue) external;

    function setOracleAcceptanceAmount(uint256 _newValue) external;

    function setDisputeFeeAmount(uint256 _newValue) external;

    function setProposalSubmitPrice(uint256 _newValue) external;

    function setQuorum(uint256 _newValue) external;
}
