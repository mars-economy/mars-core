// contracts/MarsERC20TokenV2.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./MarsERC20Token.sol";

contract MarsERC20TokenV2 is MarsERC20Token {
    uint256 newValue;

    function setValue(uint256 _new) public {
        newValue = _new;
    }

    function getValue() public view returns (uint256) {
        return newValue;
    }
}
