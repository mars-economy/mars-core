// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

interface IMarsERC20 {
    event MarsMint(address _to, uint256 _value, uint256 _option);

    function mint(
        address _to,
        uint256 _value,
        uint256 _option
    ) external;

    function mint(address _to, uint256 _value) external;

    function burn(address _from, uint256 _value) external;

    function setLockPeriod(uint256 _newValue) external;

    function setEmissionController(address _addr) external;

    function getLockPeriod() external view returns (uint256);

    function getEmissionController() external view returns (address);
}
