// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IMarsERC20 {
    event MarsMint(address _to, uint256 _value, uint256 _option);

    function mint(
        address _to,
        uint256 _value,
        uint256 _option
    ) external;

    function setLockPeriod(uint256 _newValue) external;

    function getLockPeriod() external view returns (uint256);
}
