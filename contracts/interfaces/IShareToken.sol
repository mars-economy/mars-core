// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../dependencies/tokens/IERC1155.sol";
import "./IPredictionMarket.sol";

interface IShareToken is IERC1155 {
    function registerMarket(IPredictionMarket market, uint256 numOutcomes) external;
    //    function unsafeTransferFrom(address _from, address _to, uint256 _id, uint256 _value) public;
    //    function unsafeBatchTransferFrom(address _from, address _to, uint256[] memory _ids, uint256[] memory _values) public;
    //    function claimTradingProceeds(IMarket _market, address _shareHolder, bytes32 _fingerprint) external returns (uint256[] memory _outcomeFees);
    //    function getMarket(uint256 _tokenId) external view returns (IMarket);
    //    function getOutcome(uint256 _tokenId) external view returns (uint256);
    //    function getTokenId(IMarket _market, uint256 _outcome) public pure returns (uint256 _tokenId);
    //    function getTokenIds(IMarket _market, uint256[] memory _outcomes) public pure returns (uint256[] memory _tokenIds);
    //    function buyCompleteSets(IMarket _market, address _account, uint256 _amount) external returns (bool);
    //    function buyCompleteSetsForTrade(IMarket _market, uint256 _amount, uint256 _longOutcome, address _longRecipient, address _shortRecipient) external returns (bool);
    //    function sellCompleteSets(IMarket _market, address _holder, address _recipient, uint256 _amount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    //    function sellCompleteSetsForTrade(IMarket _market, uint256 _outcome, uint256 _amount, address _shortParticipant, address _longParticipant, address _shortRecipient, address _longRecipient, uint256 _price, address _sourceAccount, bytes32 _fingerprint) external returns (uint256 _creatorFee, uint256 _reportingFee);
    //    function totalSupplyForMarketOutcome(IMarket _market, uint256 _outcome) public view returns (uint256);
    //    function balanceOfMarketOutcome(IMarket _market, uint256 _outcome, address _account) public view returns (uint256);
    //    function lowestBalanceOfMarketOutcomes(IMarket _market, uint256[] memory _outcomes, address _account) public view returns (uint256);
}
