// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ShieldFI is ERC20 {
    constructor(string memory _name, string memory _symbol, address _payoutTokenHolder) ERC20(_name, _symbol) {
        this._mint(_payoutTokenHolder, 100000 * 1e18); // Mint to the contracct responsible for payouts
        this._mint(msg.sender, 100000 * 1e18); // Mint to the contracct responsible for payouts
    }
}

