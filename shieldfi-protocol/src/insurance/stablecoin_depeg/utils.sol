// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// Extend IERC20 with decimals() and totalSupply() (totalSupply is in IERC20 already)
interface IERC20Metadata is IERC20 {
    function decimals() external view returns (uint8);
}

/// @notice Utility library for simple TVL-based scoring & insured profit rate estimation.
/// @dev IMPORTANT: _priceWad is assumed to be a price with 18 decimals (1e18 == $1).
library Utils {
    // TVL thresholds in USD (plain integers: 100_000_000 == $100,000,000)
    uint256 internal constant TVL_MEDIUM_TRUST_USD = 100_000_000; // $1M
    uint256 internal constant TVL_HIGH_TRUST_USD   = 1_000_000_000; // $1B (or adjust as needed)

    /// @notice Return a suggested purchase amount (20% of TVL USD by default).
    /// @param _insuredStableCoin address of the token
    /// @param _priceWad price of one token, scaled to 18 decimals (1e18 == $1)
    /// @return purchaseAmountUSD suggested amount in USD (plain integer, no extra decimals)
    function calculate_insured_profit_rate(
        address _insuredStableCoin,
        uint256 _priceWad
    ) internal view returns (uint256) {
        uint256 tvlScore = calculate_tvl_score(_insuredStableCoin, _priceWad, "DAI");
        // Example policy: allow up to 20% of TVL as purchase amount
        return (tvlScore * 20) / 100;
    }

    /// @notice Compute TVL in USD (rounded down to nearest USD).
    /// @dev totalSupply * price / (10**decimals) / 1e18  => plain USD integer
    function _calculate_tvl_usd(
        IERC20Metadata _token,
        uint256 _priceWad
    ) internal view returns (uint256) {
        uint256 decimals = _token.decimals();
        uint256 supply =  _token.totalSupply();

        // tvlUSD = (supply * priceWad) / (10**decimals) / 1e18
        // Rearranged to reduce precision loss: do multiply first (may be large but within uint256 for reasonable tokens)
        uint256 scaled = supply * _priceWad;
        uint256 denom = (10 ** uint256(decimals)) * 1e18;
        uint256 tvlUSD = scaled / denom;

        return tvlUSD;
    }

    /// @notice Simple TVL score: 30/60/100 based on thresholds (in USD).
    function calculate_tvl_score(
        address _insuredStableCoin,
        uint256 _priceWad,
        string memory _tokenSymbol
    ) internal view returns (uint256) {
        IERC20Metadata token = IERC20Metadata(_insuredStableCoin);
        
        if (keccak256(bytes(_tokenSymbol)) == keccak256("DAI")) {
            uint256 tvl = _calculate_tvl_usd(token, _priceWad);

            if (tvl < TVL_MEDIUM_TRUST_USD) {
                return 30;
            } else if (tvl >= TVL_MEDIUM_TRUST_USD && tvl < TVL_HIGH_TRUST_USD) {
                return 60;
            } else {
                return 100;
            }
        }

        return 10;
    }
}