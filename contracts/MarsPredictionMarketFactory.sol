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
    mapping(bytes16 => Category) public categories;
    mapping(bytes16 => Milestone) public milestones;
    mapping(address => PredictionMarket) public predictionMarkets;
    // address[] markets;

    address public addressResolver;
    address settlement;

    function initialize(address _addressResolver, address _settlement) external initializer {
        __Ownable_init();

        addressResolver = _addressResolver;
        settlement = _settlement;
    }

    function updateCategory(
        bytes16 uuid,
        uint8 position,
        string calldata name,
        string calldata description
    ) external override onlyOwner {
        // Category memory category;
        // category.position = position;
        // category.name = name;
        // category.description = description;

        // categories[uuid] = category;

        emit CategoryUpdatedEvent(uuid, position, name, description);
    }

    function updateMilestone(
        bytes16 uuid,
        bytes16 categoryUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        MilestoneStatus status
    ) external override onlyOwner {
        // Milestone memory milestone;
        // milestone.categoryUuid = categoryUuid;
        // milestone.position = position;
        // milestone.name = name;
        // milestone.description = description;
        // milestone.status = status;

        // milestones[uuid] = milestone;

        emit MilestoneUpdatedEvent(uuid, categoryUuid, position, name, description, status);
    }

    function createMarket(
        bytes16 milestoneUuid,
        uint8 position,
        string calldata name,
        string calldata description,
        address token,
        uint256 dueDate,
        Market.Outcome[] calldata outcomes
    ) external override onlyOwner returns (address) {
        require(dueDate > block.timestamp, "MARS: Invalid prediction market due date");

        // PredictionMarket memory market;
        // market.milestoneUuid = milestoneUuid;
        // market.position = position;
        // market.name = name;
        // market.description = description;

        MarsPredictionMarket predictionMarket = MarsPredictionMarket(_createMarketContract(token, dueDate, settlement, outcomes, owner()));

        // predictionMarkets[address(predictionMarket)] = market;
        emit PredictionMarketCreatedEvent(milestoneUuid, position, name, description, token, dueDate, address(predictionMarket));
        // markets.push(address(predictionMarket));

        return address(predictionMarket);
    }

    function _createMarketContract(
        address token,
        uint256 dueDate,
        address settlement,
        Market.Outcome[] calldata outcomes,
        address owner
    ) internal returns (address) {
        bytes memory data = abi.encodeWithSelector(MarsPredictionMarket.initialize.selector, token, dueDate, settlement, outcomes, owner);
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

    // //Obsolete
    // function addOutcome(
    //     address predictionMarket,
    //     bytes16 uuid,
    //     uint8 position,
    //     string calldata name
    // ) external override onlyOwner {
    //     MarsPredictionMarket(predictionMarket).addOutcome(uuid, position, name);
    // emit OutcomeChangedEvent(uuid, predictionMarket, position, name);
    // }

    // function getMarkets() external view override returns (address[] memory) {
    //     return markets;
    // }
}
