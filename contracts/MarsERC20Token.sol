// contracts/MarsERC20Token.sol
// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./dependencies/tokens/IMarsERC20.sol";

contract MarsERC20Token is IMarsERC20, ERC20, Ownable {
    mapping(address => uint256) public lockedAmount;
    mapping(uint256 => uint256) public fundsLeft;

    uint256 lockPeriod;

    function mint(
        address _to,
        uint256 _amount,
        uint256 _option
    ) external override onlyOwner {
        require(fundsLeft[_option] >= _amount);

        fundsLeft[_option] -= _amount;
        if (_option == 0) {
            lockedAmount[_to] += _amount;
        }

        _mint(_to, _amount);
        emit MarsMint(_to, _amount, _option);
    }

    constructor(
        string memory _tokenName,
        string memory _tokenSymbol,
        uint256 _lockPeriod
    ) ERC20(_tokenName, _tokenSymbol) {
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

    function setEmissionController(address _addr) external override onlyOwner {
        emissionController = _addr;
    }

    function getLockPeriod() external view override returns (uint256) {
        return lockPeriod;
    }

    function getEmissionController() external view override returns (address) {
        return emissionController;
    }
}
