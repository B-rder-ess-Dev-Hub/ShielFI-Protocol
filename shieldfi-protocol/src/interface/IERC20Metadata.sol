import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Extend IERC20 with decimals() and totalSupply() (totalSupply is in IERC20 already)
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
}