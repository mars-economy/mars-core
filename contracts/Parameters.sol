// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract Parameters is Initializable, OwnableUpgradeable {
    address receiver; //wallet that receives protocol fee

    uint256 protocolFee = 33334;
    uint256 oracleFee = 66666;

    uint256 divisor = 100000;

    function initialize(address _receiver) external initializer {
        __Ownable_init();

        receiver = _receiver;
    }

    function getOracleFee() external view returns (uint256, uint256) {
        return (oracleFee, divisor);
    }

    function getProtocolFee()
        external
        view
        returns (
            uint256,
            uint256,
            address
        )
    {
        return (protocolFee, divisor, receiver);
    }

    function setReceiver(address _newValue) external onlyOwner {
        receiver = _newValue;
    }

    function setProtocolFee(uint256 _newValue) external onlyOwner {
        protocolFee = _newValue;
    }

    function setOracleFee(uint256 _newValue) external onlyOwner {
        oracleFee = _newValue;
    }

    function setDivisor(uint256 _newValue) external onlyOwner {
        divisor = _newValue;
    }

    //getters setters
}
