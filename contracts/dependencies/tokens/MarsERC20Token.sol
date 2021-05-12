// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "../libraries/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "../libraries/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IERC20.sol";
import "./IMarsERC20.sol";

contract MarsERC20Token is IMarsERC20, Initializable, OwnableUpgradeable {
    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public lockedUntil;
    mapping(Option => uint256) fundsLeft;

    uint256 public override totalSupply;
    uint8 public decimals;
    string public symbol;
    string public name;

    uint256 lockPeriod;

    function transferLocked(
        address _to,
        uint256 _value,
        Option _option
    ) external override onlyOwner returns (bool success) {
        require(balances[address(this)] >= _value);

        require(fundsLeft[_option] - _value >= 0);
        if (_option == Option.CORE_TEAM) {
            lockedUntil[_to] = lockPeriod;
        }

        balances[address(this)] -= _value;
        balances[_to] += _value;

        emit Mint(_to, _value, _option);
        return true;
    }

    function initialize(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) external initializer {
        __Ownable_init();

        totalSupply = _initialAmount; // Update total supply
        name = _tokenName; // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes
        lockPeriod = 1683774000; //Thu May 11 2023 06:00:00 GMT+0300 (Moscow Standard Time)

        fundsLeft[Option.CORE_TEAM] = 100_000_000 * 10**decimals;
        fundsLeft[Option.STRATEGIC_INVESTORS] = 100_000_000 * 10**decimals;
        fundsLeft[Option.ECOSYSTEM] = 350_000_000 * 10**decimals;
        fundsLeft[Option.FUNDRASING] = 50_000_000 * 10**decimals;
        fundsLeft[Option.COMMON_POOL] = 400_000_000 * 10**decimals;
    }

    function transfer(address _to, uint256 _value) external override returns (bool success) {
        require(lockedUntil[msg.sender] < block.timestamp, "TOKENS ARE LOCKED");

        require(balances[msg.sender] >= _value);
        balances[msg.sender] -= _value;
        balances[_to] += _value;
        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) external override returns (bool success) {
        require(lockedUntil[msg.sender] < block.timestamp, "TOKENS ARE LOCKED");

        uint256 allowance = allowed[_from][msg.sender];
        require(balances[_from] >= _value && allowance >= _value);
        balances[_to] += _value;
        balances[_from] -= _value;
        if (allowance < MAX_UINT256) {
            allowed[_from][msg.sender] -= _value;
        }
        emit Transfer(_from, _to, _value);
        return true;
    }

    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external override returns (bool success) {
        require(lockedUntil[msg.sender] < block.timestamp, "TOKENS ARE LOCKED");

        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
