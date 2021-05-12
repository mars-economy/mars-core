// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./IERC20.sol";

interface IMarsERC20 is IERC20 {
    event Mint(address indexed _to, uint256 _value, Option _option);

    enum Option {CORE_TEAM, STRATEGIC_INVESTORS, ECOSYSTEM, FUNDRASING, COMMON_POOL}

    function transferLocked(
        address _to,
        uint256 _value,
        Option _option
    ) external returns (bool success);
}
