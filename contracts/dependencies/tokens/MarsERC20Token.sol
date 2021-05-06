// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

contract MarsERC20Token is IERC20 {
    event Mint(address indexed _to, uint256 _value, uint256 indexed _option);

    uint256 private constant MAX_UINT256 = 2**256 - 1;
    mapping(address => uint256) public balances;
    mapping(address => mapping(address => uint256)) public allowed;
    mapping(address => uint256) public lockedUntil;

    string public name;
    uint8 public decimals;
    string public symbol;
    uint256 public override totalSupply;

    address owner;

    uint256 coreTeam = 20_000_000 * 10**decimals;
    uint256 strategicinvestors = 15_000_000 * 10**decimals;
    uint256 ecosystem = 10_000_000 * 10**decimals;
    uint256 fundraising = 2_000_000 * 10**decimals;
    uint256 common = 1_000_000 * 10**decimals;

    uint256 coreTeamMinted;
    uint256 strategicinvestorsMinted;
    uint256 ecosystemMinted;
    uint256 fundraisingMinted;
    uint256 commonMinted;

    uint256 lockPeriod = 7 days;

    //can change to enum
    function transferLocked(
        address _to,
        uint256 _value,
        uint256 _option
    ) external returns (bool success) {
        require(msg.sender == owner, "ONLY OWNER CAN MINT TOKENS");

        require(balances[msg.sender] >= _value);

        if (_option == 0) {
            require(coreTeam > coreTeamMinted + _value);
            coreTeamMinted += _value;
        } else if (_option == 1) {
            require(strategicinvestors > strategicinvestorsMinted + _value);
            strategicinvestorsMinted += _value;
        } else if (_option == 2) {
            require(ecosystem > ecosystemMinted + _value);
            ecosystemMinted += _value;
        } else if (_option == 3) {
            require(fundraising > fundraisingMinted + _value);
            fundraisingMinted += _value;
        } else if (_option == 4) {
            require(common > commonMinted + _value);
            commonMinted += _value;
        }

        balances[msg.sender] -= _value;
        balances[_to] += _value;
        lockedUntil[_to] = block.timestamp + lockPeriod;

        emit Mint(_to, _value, _option);
        return true;
    }

    constructor(
        uint256 _initialAmount,
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol
    ) {
        balances[msg.sender] = _initialAmount; // Give the creator all initial tokens
        totalSupply = _initialAmount; // Update total supply
        name = _tokenName; // Set the name for display purposes
        decimals = _decimalUnits; // Amount of decimals for display purposes
        symbol = _tokenSymbol; // Set the symbol for display purposes

        owner = msg.sender;
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

    function setGovernance(address _governor) external {}
}
