// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./dependencies/tokens/IMarsERC20.sol";

contract MarsERC20Token is IMarsERC20, Initializable, OwnableUpgradeable, ERC20Upgradeable {
    mapping(address => uint256) public lockedUntil;
    mapping(Option => uint256) fundsLeft;

    uint256 public lockPeriod;

    function transferLocked(
        address _to,
        uint256 _value,
        Option _option
    ) external override onlyOwner returns (bool success) {
        require(balanceOf(address(this)) >= _value);
        require(fundsLeft[_option] - _value >= 0);

        _transfer(address(this), _to, _value);
        fundsLeft[_option] -= _value;
        if (_option == Option.CORE_TEAM) {
            lockedUntil[_to] = lockPeriod;
        }

        return true;
    }

    function initialize(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) external initializer {
        __Ownable_init();
        __ERC20_init(_tokenName, _tokenSymbol);
        _mint(address(this), _initialAmount);

        lockPeriod = 1683774000; //Thu May 11 2023 06:00:00 GMT+0300 (Moscow Standard Time)

        fundsLeft[Option.CORE_TEAM] = 100_000_000 * 1 ether;
        fundsLeft[Option.STRATEGIC_INVESTORS] = 100_000_000 * 1 ether;
        fundsLeft[Option.ECOSYSTEM] = 350_000_000 * 1 ether;
        fundsLeft[Option.FUNDRASING] = 50_000_000 * 1 ether;
        fundsLeft[Option.COMMON_POOL] = 400_000_000 * 1 ether;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        require(lockedUntil[msg.sender] < block.timestamp, "MarsERC20: Tokens are locked until lockPeriod");
    }
}
