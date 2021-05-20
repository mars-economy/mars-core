// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

// import "./dependencies/libraries/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
// import "./dependencies/libraries/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import "./dependencies/libraries/InitializableAdminUpgradeabilityProxy.sol";

import "./interfaces/IPredictionMarketFactory.sol";
import "./interfaces/IAddressResolver.sol";
import "./MarsPredictionMarket.sol";
import "./libraries/Market.sol";

import "hardhat/console.sol"; //TODO: REMOVE

contract MarsPredictionMarketFactory is IPredictionMarketFactory, Initializable, OwnableUpgradeable {
    address public addressResolver;
    address settlement;

    function initialize(address _addressResolver, address _settlement) external initializer {
        __Ownable_init();

        addressResolver = _addressResolver;
        settlement = _settlement;
    }

    function createMarket(
        address token,
        uint256 _predictionTimeEnd,
        Market.Outcome[] calldata outcomes,
        uint256 startSharePrice,
        uint256 endSharePrice
    ) external override onlyOwner returns (address) {
        require(_predictionTimeEnd > block.timestamp, "MARS: Invalid prediction market due date");

        MarsPredictionMarket predictionMarket =
            MarsPredictionMarket(_createMarketContract(token, _predictionTimeEnd, outcomes, owner(), startSharePrice, endSharePrice));

        emit PredictionMarketCreatedEvent(address(predictionMarket));

        return address(predictionMarket);
    }

    function _createMarketContract(
        address token,
        uint256 dueDate,
        Market.Outcome[] calldata outcomes,
        address owner,
        uint256 startSharePrice,
        uint256 endSharePrice
    ) internal returns (address) {
        bytes memory data =
            abi.encodeWithSelector(
                MarsPredictionMarket.initialize.selector,
                token,
                dueDate,
                outcomes,
                owner,
                startSharePrice,
                endSharePrice
            );
        InitializableAdminUpgradeabilityProxy proxy = new InitializableAdminUpgradeabilityProxy();
        proxy.initialize(getOrCreateImplementation(type(MarsPredictionMarket).creationCode, "MARS"), address(this), data);
        return address(proxy);
    }

    function getOrCreateImplementation(bytes memory bytecode, bytes32 salt) internal returns (address implementation) {
        bytes32 hash = keccak256(abi.encodePacked(bytes1(0xff), address(this), salt, keccak256(bytecode)));
        implementation = address(uint160(uint256(hash)));

        if (isContract(implementation)) {
            return implementation;
        }
        assembly {
            implementation := create2(0, add(bytecode, 32), mload(bytecode), salt)
        }
    }

    function isContract(address account) internal view returns (bool) {
        // This method relies on extcodesize, which returns 0 for contracts in
        // construction, since the code is only stored at the end of the
        // constructor execution.

        uint256 size;
        // solhint-disable-next-line no-inline-assembly
        assembly {
            size := extcodesize(account)
        }
        return size > 0;
    }
}
