// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IShareTokenFactory {
    function createToken(uint256 outcome) external returns (address);
}
