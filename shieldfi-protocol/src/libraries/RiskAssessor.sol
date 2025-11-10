// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @notice Utility library for simple TVL-based scoring & insured profit rate estimation.
/// @dev IMPORTANT: _priceWad is assumed to be a price with 18 decimals (1e18 == $1).
contract RiskAssessor {
    // TVL thresholds in USD (plain integers: 100_000_000 == $100,000,000)
    uint256 internal constant TVL_MEDIUM_TRUST_USD = 100_000_000; // $1M
    uint256 internal constant TVL_HIGH_TRUST_USD   = 1_000_000_000; // $1B (or adjust as needed)
    uint256 internal constant PROTOCOL_AGE_MEDIUM_TRUST = 4;
    uint256 internal constant PROTOCOL_AGE_MEDIUM_HIGH = 10;
    uint256 internal constant HISTORICAL_EXPLOIT_MEDIUM_TRUST = 3;
    uint256 internal constant HISTORICAL_EXPLOIT_MEDIUM_HIGH = 0;

    /// @notice Compute TVL in USD (rounded down to nearest USD).
    /// @dev totalSupply * price / (10**decimals) / 1e18  => plain USD integer
    function _calculate_tvl_usd(
        IERC20Metadata _token,
        address _pricefeed
    ) internal view returns (uint256) {
        dataFeed = AggregatorV3Interface(0x1b44F3514812d835EB1BDB0acB33d3fA3351Ee43);
        // prettier-ignore
        (
        /* uint80 roundId */
        ,
        int256 answer,
        /*uint256 startedAt*/
        ,
        /*uint256 updatedAt*/
        ,
        /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        
        uint256 _priceWad = uint256(answer);

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
        uint256 _priceWad
    ) internal view returns (uint256) {
        IERC20Metadata token = IERC20Metadata(_insuredStableCoin);
        
        if (keccak256(bytes(token.symbol())) == keccak256("DAI")) {
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

    function calculate_protocol_age_score(uint256 _age) internal pure returns (uint256) {
        if (_age < PROTOCOL_AGE_MEDIUM_TRUST) {
            return 30;
        } else if (_age >= PROTOCOL_AGE_MEDIUM_HIGH && _age < PROTOCOL_AGE_MEDIUM_HIGH){
            return 60;
        } else {
            return 100;
        }
    }

    function calculate_historical_exploit_score(uint256 _noOfEXploits) internal pure returns (uint256) {
        if (_noOfEXploits >= HISTORICAL_EXPLOIT_MEDIUM_TRUST) {
            return 30;
        } else if (_noOfEXploits < HISTORICAL_EXPLOIT_MEDIUM_HIGH && _noOfEXploits > HISTORICAL_EXPLOIT_MEDIUM_HIGH){
            return 60;
        } else {
            return 100;
        }
    }
}