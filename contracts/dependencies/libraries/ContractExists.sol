// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// Utility to check if the address actually contains a contract based on size.
// Note: This will fail if called from the contract's constructor
library ContractExists {
    function exists(address _address) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(_address)
        }
        return size > 0;
    }
}
