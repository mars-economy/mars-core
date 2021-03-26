// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "../dependencies/tokens/ERC20.sol";

contract MarsToken is ERC20 {
    constructor() ERC20(1000000000000000000000000000, "MARS Token", 18, "$MARS") {}
}
