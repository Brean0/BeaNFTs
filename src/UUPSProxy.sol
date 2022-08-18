// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.10;

import "Openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSProxy is ERC1967Proxy {
    constructor (address _implementation, bytes memory _data) ERC1967Proxy(_implementation, _data) {}
}