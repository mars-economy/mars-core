// contracts/MarsERC20Token.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "./dependencies/tokens/IMarsERC20.sol";

contract MarsERC20Token is IMarsERC20, Initializable, ERC20Upgradeable, OwnableUpgradeable {
    mapping(address => uint256) public lockedAmount;
    mapping(uint256 => uint256) fundsLeft;

    uint256 public lockPeriod;

    function mint(
        address _to,
        uint256 _value,
        uint256 _option
    ) external override onlyOwner returns (bool success) {
        require(fundsLeft[_option] >= _value);

        fundsLeft[_option] -= _value;
        if (_option == 0) {
            lockedAmount[_to] += _value;
        }

        _mint(_to, _value);
        emit MarsMint(_to, _value, _option);

        return true;
    }

    function initialize(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _lockPeriod
    ) external initializer {
        __Ownable_init();
        __ERC20_init(_tokenName, _tokenSymbol);

        lockPeriod = _lockPeriod;

        fundsLeft[0] = 100_000_000 * 1 ether;
        fundsLeft[1] = 100_000_000 * 1 ether;
        fundsLeft[2] = 350_000_000 * 1 ether;
        fundsLeft[3] = 50_000_000 * 1 ether;
        fundsLeft[4] = 400_000_000 * 1 ether;
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override {
        if (from == address(0)) return;

        if (block.timestamp < lockPeriod)
            require(balanceOf(from) - lockedAmount[from] >= amount, "MarsERC20: Tokens are locked until lockPeriod");
    }

    function setLockPeriod(uint256 _newValue) external override onlyOwner {
        lockPeriod = _newValue;
    }
}
