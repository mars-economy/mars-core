// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "../interfaces/IPredictionMarket.sol";

library TokenId {
    function getTokenId(address market, uint256 outcome) internal pure returns (uint256 tokenId) {
        return getTokenId(IPredictionMarket(market), outcome);
    }

    function getTokenId(IPredictionMarket market, uint256 outcome) internal pure returns (uint256 tokenId) {
        bytes memory tokenIdBytes = abi.encodePacked(market, uint8(outcome));
        assembly {
            tokenId := mload(add(tokenIdBytes, add(0x20, 0)))
        }
    }

    function getTokenIds(address market, uint256[] memory outcomes) internal pure returns (uint256[] memory tokenIds) {
        return getTokenIds(IPredictionMarket(market), outcomes);
    }

    function getTokenIds(IPredictionMarket market, uint256[] memory outcomes) internal pure returns (uint256[] memory tokenIds) {
        tokenIds = new uint256[](outcomes.length);
        for (uint256 i = 0; i < outcomes.length; i++) {
            tokenIds[i] = getTokenId(market, outcomes[i]);
        }
    }

    function unpackTokenId(uint256 tokenId) internal pure returns (address market, uint256 outcome) {
        assembly {
            market := shr(96, and(tokenId, 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF000000000000000000000000))
            outcome := shr(88, and(tokenId, 0x0000000000000000000000000000000000000000FF0000000000000000000000))
        }
    }
}
