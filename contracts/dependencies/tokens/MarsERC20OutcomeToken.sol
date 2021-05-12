// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

// import "../libraries/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
// import "../libraries/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "./IERC20.sol";

contract MarsERC20OutcomeToken is IERC20, Initializable, OwnableUpgradeable {
    event Mint(address indexed _to, uint256 _value, uint256 _totalSupply);

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public override totalSupply;

    function initialize(
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) external initializer {
        __Ownable_init();
        name = _tokenName; // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes
    }

    function transfer(address _to, uint256 _value) external override returns (bool success) {
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

    function mint(address _to, uint256 _value) external onlyOwner returns (bool success) {
        totalSupply += _value;
        balances[_to] += _value;

        emit Mint(_to, _value, totalSupply);

        return true;
    }

    function balanceOf(address _owner) external view override returns (uint256 balance) {
        return balances[_owner];
    }

    function approve(address _spender, uint256 _value) external override returns (bool success) {
        allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function allowance(address _owner, address _spender) external view override returns (uint256 remaining) {
        return allowed[_owner][_spender];
    }
}
