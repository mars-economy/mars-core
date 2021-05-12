// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "./dependencies/libraries/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./interfaces/IAddressResolver.sol";

contract MarsAddressResolver is IAddressResolver, OwnableUpgradeable {
    mapping(bytes32 => address) public repository;

    // constructor(address governor)  {}

    function getAddress(bytes32 name) external view override returns (address) {
        return repository[name];
    }

    function requireAddress(bytes32 name, string calldata errorMessage) external view override returns (address contractAddress) {
        contractAddress = repository[name];
        require(contractAddress != address(0), errorMessage);
    }

    function registerAddress(bytes32 name, address contractAddress) public onlyOwner {
        repository[name] = contractAddress;
        emit ContractRegistered(name, contractAddress);
    }
}
