// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import { Utils } from "../src/insurance/stablecoin_depeg/utils.sol";

contract UtilsTest is Test {
    function calculate_insured_profit_rate(
        address _insuredStableCoin,
        uint256 _priceWad
    ) external view returns (uint256) {
        return Utils.calculate_insured_profit_rate(_insuredStableCoin, _priceWad);
    }
}