// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../Parameters.sol";

contract ParametersV2 is Parameters {
    uint256 value;

    function setValue(uint256 _newValue) external {
        value = _newValue;
    }

    function getValue() external view returns (uint256) {
        return value;
    }
}
