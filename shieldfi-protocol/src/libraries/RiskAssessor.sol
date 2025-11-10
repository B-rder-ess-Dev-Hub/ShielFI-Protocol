// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC20} from "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

/// @notice Defines the categories of risk the protocol covers.
enum RISK_CATEGORY {
    SMART_CONTRACT,
    STABLECOIN,
    LIQUIDITY_POOL
}

interface IERC20Metadata is IERC20 {
    function symbol() external view returns (string memory);
    function decimals() external view returns (uint8);
}

/// @notice Utility library for simple TVL-based scoring & insured profit rate estimation.
/// @dev IMPORTANT: _priceWad is assumed to be a price with 18 decimals (1e18 == $1).
contract RiskAssessor {
    // TVL thresholds in USD (plain integers: 100_000_000 == $100,000,000)
    uint256 internal constant TVL_MEDIUM_TRUST_USD = 100_000_000; // $100M
    uint256 internal constant TVL_HIGH_TRUST_USD   = 1_000_000_000; // $1B (or adjust as needed)
    uint256 internal constant PROTOCOL_AGE_MEDIUM_TRUST = 4 * 31536000; // Approx 4 years in seconds
    uint256 internal constant PROTOCOL_AGE_HIGH_TRUST = 10 * 31536000; // Approx 10 years in seconds
    uint256 internal constant HISTORICAL_EXPLOIT_MEDIUM_TRUST = 3;
    uint256 internal constant HISTORICAL_EXPLOIT_HIGH_TRUST = 0;

    /// @notice Compute TVL in USD (rounded down to nearest USD).
    /// @dev totalSupply * price / (10**decimals) / 1e18  => plain USD integer
    function _calculate_tvl_usd(
        IERC20Metadata _token,
        address _priceFeed
    ) internal view returns (uint256) {
        AggregatorV3Interface priceFeed = AggregatorV3Interface(_priceFeed);
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
        ) = priceFeed.latestRoundData();
        
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
        address _priceFeed
    ) internal view returns (uint256) {
        IERC20Metadata token = IERC20Metadata(_insuredStableCoin);
        
        uint256 tvl = _calculate_tvl_usd(token, _priceFeed);

        if (tvl < TVL_MEDIUM_TRUST_USD) {
            return 100;
        } else if (tvl >= TVL_MEDIUM_TRUST_USD && tvl < TVL_HIGH_TRUST_USD) {
            return 60;
        } else {
            return 30;
        }
    }

    function calculate_protocol_age_score(uint256 _age) internal pure returns (uint256) {
        if (_age < PROTOCOL_AGE_MEDIUM_TRUST) {
            return 100;
        } else if (_age >= PROTOCOL_AGE_MEDIUM_TRUST && _age < PROTOCOL_AGE_HIGH_TRUST){
            return 60;
        } else {
            return 30;
        }
    }

    function calculate_historical_exploit_score(uint256 _noOfEXploits) internal pure returns (uint256) {
        if (_noOfEXploits >= HISTORICAL_EXPLOIT_MEDIUM_TRUST) {
            return 100;
        } else if (_noOfEXploits < HISTORICAL_EXPLOIT_MEDIUM_TRUST && _noOfEXploits > HISTORICAL_EXPLOIT_HIGH_TRUST){
            return 60;
        } else {
            return 30;
        }
    }

    function assessProtocolRisk(
        address _tokenAddress,
        address _priceFeed,
        RISK_CATEGORY _category,
        uint256 _age,
        uint256 _noOfExploits
    ) public view returns (uint256 finalRiskScore) {
        uint256 ageScore = (calculate_protocol_age_score(_age) * 10) / 34; // scaled to 30 max but also not perfect // age is fetched offchain
        uint256 exploitScore = (calculate_historical_exploit_score(_noOfExploits) * 10) / 25; // scaled to 40 max but also not perfect // Using a hard coded value for now // Fetch from an oracle if exists else offchain

        finalRiskScore = (ageScore + exploitScore);

        if (_category == RISK_CATEGORY.STABLECOIN) {
            uint256 tvlScore = calculate_tvl_score(_tokenAddress, _priceFeed) / 34; // Scale to max of 30 but not perfect
            finalRiskScore += tvlScore;
        } else {
            finalRiskScore = 20; // Base risk score for tvl for non stable coins
        }

        finalRiskScore = finalRiskScore / 3;
        
        // Ensure the score is within the 1-100 bounds
        if (finalRiskScore > 100) return 100;
        if (finalRiskScore == 0) return 1; // Minimum risk score of 1

        return finalRiskScore;
    }
}