// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

// Assume this contract exists or will be provided by your integration layer
interface IExternalDataFeed {
    function getTVLUSD(address _protocol) external view returns (uint256); // Returns TVL in plain USD
    function getProtocolAgeInDays(address _protocol) external view returns (uint256);
    function getExploitCount(address _protocol) external view returns (uint256);
}

contract RiskAssessor {
    // Risk Contribution Weights (must sum to 100)
    uint256 private constant WEIGHT_TVL = 30; // High weight means TVL is important
    uint256 private constant WEIGHT_AGE = 30;
    uint256 private constant WEIGHT_EXPLOIT = 40;
    
    // TVL thresholds in USD (plain integers)
    uint256 internal constant TVL_MEDIUM_TRUST_USD = 100_000_000; // $100M
    uint256 internal constant TVL_HIGH_TRUST_USD   = 1_000_000_000; // $1B 
    uint256 internal constant PROTOCOL_AGE_HIGH_RISK_DAYS = 90; 
    uint256 internal constant PROTOCOL_AGE_LOW_RISK_DAYS = 365; // 1 year+

    IExternalDataFeed public dataFeed;

    constructor(address _dataFeedAddress) {
        dataFeed = IExternalDataFeed(_dataFeedAddress);
    }

    /// @notice Calculates the final risk score (1-100) for a protocol.
    /// @param _protocolAddress The address of the protocol to be assessed.
    /// @return finalRiskScore The calculated score, where 100 is max risk.
    function assessProtocolRisk(address _protocolAddress) public view returns (uint256 finalRiskScore) {
        // Fetch raw data
        uint256 tvl = dataFeed.getTVLUSD(_protocolAddress);
        uint256 age = dataFeed.getProtocolAgeInDays(_protocolAddress);
        uint256 exploits = dataFeed.getExploitCount(_protocolAddress);

        // 1. TVL Risk Score (Inverted: Low TVL adds HIGH risk)
        uint256 tvlScore;
        if (tvl < TVL_MEDIUM_TRUST_USD) {
            tvlScore = WEIGHT_TVL; // Max risk contribution (30)
        } else if (tvl < TVL_HIGH_TRUST_USD) {
            tvlScore = WEIGHT_TVL * 2 / 3; // Medium risk (20)
        } else {
            tvlScore = WEIGHT_TVL / 3; // Low risk contribution (10)
        }

        // 2. Protocol Age Risk Score (Inverted: Young age adds HIGH risk)
        uint256 ageScore;
        if (age < PROTOCOL_AGE_HIGH_RISK_DAYS) {
            ageScore = WEIGHT_AGE; // Max risk contribution (30)
        } else if (age < PROTOCOL_AGE_LOW_RISK_DAYS) {
            ageScore = WEIGHT_AGE * 2 / 3; // Medium risk (20)
        } else {
            ageScore = WEIGHT_AGE / 3; // Low risk contribution (10)
        }

        // 3. Historical Exploit Score (Higher exploits adds HIGHER risk)
        uint256 exploitScore;
        if (exploits >= 3) {
            exploitScore = WEIGHT_EXPLOIT; // Max risk contribution (40)
        } else if (exploits >= 1) {
            exploitScore = WEIGHT_EXPLOIT / 2; // Medium risk (20)
        } else {
            exploitScore = 0; // No exploits (0)
        }
        
        // Final Score (Sum of weighted scores)
        finalRiskScore = tvlScore + ageScore + exploitScore;

        // Ensure the score is within the 1-100 bounds
        if (finalRiskScore > 100) return 100;
        if (finalRiskScore == 0) return 1;

        return finalRiskScore;
    }
}