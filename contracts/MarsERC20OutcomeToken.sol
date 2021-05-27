// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MarsERC20OutcomeToken is ERC20, Ownable {
    mapping(address => uint256) stakeAmount;
    uint256 public totalStakedAmount;

    constructor(
        string memory _tokenName,
        uint8 _decimalUnits,
        string memory _tokenSymbol,
        address owner
    ) ERC20(_tokenName, _tokenSymbol) {
        // transferOwnership(owner);
    }

    // function _beforeTokenTransfer(address from, address to, uint256 amount) internal override {
    //     if (from == address(0) || to == address(0))
    //         require(msg.sender == owner());
    // }

    function mint(
        address _account,
        uint256 _amount,
        uint256 _stakeAmount
    ) external onlyOwner returns (bool) {
        stakeAmount[_account] += _stakeAmount;
        totalStakedAmount += _stakeAmount;
        _mint(_account, _amount);

        return true;
    }

    function transferStakeShare(
        address _sender,
        address _recipient,
        uint256 _amount
    ) internal {
        uint256 balance = balanceOf(_sender);
        uint256 _stakedAmount;
        if (balance != 0) {
            _stakedAmount = (_amount * stakeAmount[_sender]) / balanceOf(_sender);

            stakeAmount[_sender] -= _stakedAmount;
            stakeAmount[_recipient] += _stakedAmount;
        }
    }

    function transfer(address recipient, uint256 amount) public override returns (bool) {
        transferStakeShare(msg.sender, recipient, amount);
        super.transfer(recipient, amount);

        return true;
    }

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) public override returns (bool) {
        transferStakeShare(sender, recipient, amount);
        super.transferFrom(sender, recipient, amount);

        return true;
    }

    function stakedAmount(address _wallet) external view returns (uint256) {
        return stakeAmount[_wallet];
    }
}
