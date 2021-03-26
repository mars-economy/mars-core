// SPDX-License-Identifier: GPL-3.0
pragma solidity >=0.8.0 <0.9.0;

import "./IERC1155Receiver.sol";
import "./ERC165.sol";

abstract contract ERC1155Receiver is ERC165, IERC1155Receiver {
    constructor() {
        _registerInterface(IERC1155Receiver.onERC1155Received.selector ^ IERC1155Receiver.onERC1155BatchReceived.selector);
    }
}
