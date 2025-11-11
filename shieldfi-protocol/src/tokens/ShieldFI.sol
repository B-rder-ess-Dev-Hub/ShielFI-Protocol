// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { Errors } from "./libraries/Errors.sol";

abstract contract Pausable is Ownable {
    error CONTRACT_IS_PAUSED();

    bool private s_isPaused = false;

    modifier isActive() {
        if (s_isPaused) {
            revert CONTRACT_IS_PAUSED();
        }
        _;
    }

    function togglePause() external virtual onlyOwner returns (bool) {
        s_isPaused = !s_isPaused;

        return s_isPaused;
    }
}
// Most likely extend a pausable contract for now, native implementation
contract ShieldFI is ERC20, Pausable {

    constructor(string memory _name, string memory _symbol, address _payoutTokenHolder) ERC20(_name, _symbol) Ownable(msg.sender) {
        if (_payoutTokenHolder == address(0)) {
            revert Errors.INVALID_ADDRESS();
        }

        _mint(_payoutTokenHolder, 100000 * 1e18); // Mint to the contracct responsible for payouts
        _mint(msg.sender, 100000 * 1e18); // Mint to the contracct responsible for payouts
    }

    function mint(address _to, uint256 _amount) external isActive() onlyOwner {
        _mint(_to, _amount);
    }

    function burn(uint256 _amount) external isActive() onlyOwner {
        _burn(msg.sender, _amount);
    }
}

