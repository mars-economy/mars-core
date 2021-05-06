// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IAddressResolver {
    event ContractRegistered(bytes32 name, address contractAddress);

    function getAddress(bytes32 name) external view returns (address);

    function requireAddress(bytes32 name, string calldata errorMessage) external view returns (address);
}
