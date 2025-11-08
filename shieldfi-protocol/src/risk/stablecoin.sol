// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import { Utils } from "./libraries/Utils.sol";
import {AggregatorV3Interface} from "@chainlink/contracts@1.5.0/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract STABLECOIN {
    uint256 private constant RISK_FACTOR_TVL = 23;
    uint256 private constant RISK_FACTOR_PROTOCOL_AGE = 20;
    uint256 private constant RISK_FACTOR_AUDIT_SCORE = 32;
    uint256 private constant RISK_FACTOR_HISTORICAL_EXPLOIT = 25;
    // uint256 private constant MARKET_VOLATILITY = 

    function calculate_risk_score(address _token, address _tokenAggregator) external view returns (uint256) {
        uint256 tvl_score = Utils.calculate_tvl_score(_token, _getStableCoinPriceToUSDNormalized(_tokenAggregator));
        // uint256 protocol_age_score = (Utils.calculate_protocol_age_score(10) * RISK_FACTOR_PROTOCOL_AGE) / 100;
        // uint256 historical_exploit_score = (Utils.calculate_historical_exploit_score(10) * RISK_FACTOR_HISTORICAL_EXPLOIT) / 100;

        uint256 total_score = tvl_score;

        // rationalize to max of 10 and min of 0 and return response
        return total_score / 10;
    }

    function _getStableCoinPriceToUSDNormalized(address _aggregatorAddress) view public returns (uint256) {
        AggregatorV3Interface dataFeed = AggregatorV3Interface(_aggregatorAddress);

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

        uint8 dec = dataFeed.decimals();

        return uint256(answer) * 1e18 / (10 ** dec);
    }
}