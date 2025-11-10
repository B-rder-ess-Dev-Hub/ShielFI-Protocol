// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @notice Defines the categories of risk the protocol covers.
enum RISK_CATEGORY {
    SMART_CONTRACT,
    STABLECOIN,
    LIQUIDITY_POOL
}

/// @notice Data structure to hold the historical performance of an entire risk category.
struct RiskData {
    // Base Score is on a 1-100 scale. This is the starting point for risk assessment,
    // set by governance/risk managers.
    uint256 base_score; 
    // Total number of claims requested against policies in this category.
    uint256 no_of_claims; 
    // Cumulative value of all approved and paid-out claims (in SHD tokens, with 18 decimals).
    uint256 total_payouts; 
    // Cumulative value of all premiums collected from policies in this category (in SHD tokens, with 18 decimals).
    uint256 total_premium; 
    // NOTE: risk_factor is unused in storage as it is calculated on demand in calculateRiskFactor().
    uint256 risk_factor; 
}

/// @title RiskMatrix
/// @notice Manages and calculates historical risk data (claims vs. premiums) per category.
contract RiskMatrix {
    // Custom error for clean reverts
    error BASE_SCORE_OUT_OF_RANGE();

    // Events for off-chain monitoring
    event BaseScoreUpdated(RISK_CATEGORY indexed category, uint256 newScore);
    event HistoricalDataUpdated(RISK_CATEGORY indexed category, uint256 newClaims, uint256 newPayouts, uint256 newPremiums);

    // The main storage mapping for all risk data.
    mapping(RISK_CATEGORY => RiskData) public s_riskMatrix;
    
    constructor() {
        // Initialize base scores (1-100 scale). This is a manual, starting assessment of risk.
        // Higher score = Higher inherent risk.
        s_riskMatrix[RISK_CATEGORY.SMART_CONTRACT].base_score = 40; // Moderate/Low Base Risk
        s_riskMatrix[RISK_CATEGORY.LIQUIDITY_POOL].base_score = 60; // Medium Base Risk
        s_riskMatrix[RISK_CATEGORY.STABLECOIN].base_score = 70;     // Higher Base Risk
    }

    /// @notice Updates the base risk score for a category. (Usually restricted to a RISK_MANAGER role).
    /// @param _risk_category The category to update.
    /// @param _new_score The new base score, constrained to a 1-100 scale.
    function updateBaseScore(RISK_CATEGORY _risk_category, uint256 _new_score) external {
        // Check: Enforces the scale. The score should not exceed 100.
        if (_new_score > 100 ) {
            revert BASE_SCORE_OUT_OF_RANGE();
        }

        // Implementation: Set the new score.
        s_riskMatrix[_risk_category].base_score = _new_score;

        emit BaseScoreUpdated(_risk_category, _new_score);
    }

    /// @notice Records a new claim submission and, optionally, a payout.
    /// @dev Called by the Claims Adjudication system (e.g., ShieldFi.processClaim).
    /// @param _category The risk category.
    /// @param _claimValue The value of the claim/payout (in SHD token units).
    /// @param _isPayout True if the claim was approved and paid out.
    function updateHistoricalDataPerClaimRequest(RISK_CATEGORY _category, uint256 _claimValue, bool _isPayout) external {
        RiskData storage risk = s_riskMatrix[_category];
        risk.no_of_claims++;

        if (_isPayout) {
            // Payouts increase the 'cost' side of the Loss Ratio.
            risk.total_payouts += _claimValue;
        }

        emit HistoricalDataUpdated(_category, risk.no_of_claims, risk.total_payouts, risk.total_premium);
    }
    
    /// @notice Records a new premium collected.
    /// @dev Called by the Policy Creation system (e.g., ShieldFi.purchasePolicy).
    /// @param _category The risk category.
    /// @param _premium_value The amount of premium collected (in SHD token units).
    function updateHistoricalDataPerPremiumPaid(RISK_CATEGORY _category, uint256 _premium_value) external {
        RiskData storage risk = s_riskMatrix[_category];
        // Premiums increase the 'revenue' side of the Loss Ratio.
        risk.total_premium += _premium_value;

        emit HistoricalDataUpdated(_category, risk.no_of_claims, risk.total_payouts, risk.total_premium);
    }

    /// @notice Calculates and returns the current **Risk Factor** (a premium multiplier) for a category.
    /// @dev The Risk Factor is centered around 100, where 100 = 1.0x (no adjustment).
    /// @param _category The risk category.
    /// @return The calculated risk factor (100 = 1.0 multiplier).
    function calculateRiskFactor(RISK_CATEGORY _category) public view returns (uint256) {
        RiskData storage risk = s_riskMatrix[_category];

        // 1. Guard Check
        // If no premiums collected, we cannot calculate a meaningful ratio.
        if (risk.total_premium == 0) {
            return 100; // Returns a neutral 1.0x factor (100 is the scaling base)
        }

        // --- 2. Actuarial Loss Ratio Calculation ---

        // The Loss Ratio is: (Total Payouts / Total Premiums)
        
        // Scaling Factor: 10000 
        // This scales the ratio to a 4-decimal fixed-point integer.
        // Example: A 0.75 Loss Ratio (75%) becomes 7500. A 1.25 Loss Ratio becomes 12500.
        uint256 scaledLossRatio = (risk.total_payouts * 10000) / risk.total_premium; 
        
        // --- 3. Determine Premium Adjustment ---
        
        // Target Ratio: 8000
        // This represents an 80% Loss Ratio (8000/10000). The protocol aims for a 20% profit margin.
        uint256 targetRatio = 8000; 

        // The Risk Factor (multiplier) is centered around 100 (1.0x) and adjusted by the ratio's deviation from the target.
        
        // Scaling Divisor: 100
        // This converts the 10000-scaled difference (e.g., 2000) back to a 100-scaled adjustment (e.g., 20).
        
        if (scaledLossRatio > targetRatio) {
            // **UNPROFITABLE SCENARIO (Loss Ratio > 80%)**
            // Increase premium factor to recoup losses.
            
            // Example: Loss Ratio 10000 (1.0)
            // Difference: (10000 - 8000) = 2000
            // Adjustment: 2000 / 100 = 20
            // Final Factor: 100 + 20 = 120 (1.2x multiplier, 20% premium increase)
            return 100 + ((scaledLossRatio - targetRatio) / 100);
        } else {
            // **PROFITABLE SCENARIO (Loss Ratio < 80%)**
            // Decrease premium factor or keep it stable.
            
            // Example: Loss Ratio 6000 (0.6)
            // Difference: (8000 - 6000) = 2000
            // Adjustment: 2000 / 100 = 20
            // Final Factor: 100 - 20 = 80 (0.8x multiplier, 20% premium discount)
            return 100 - ((targetRatio - scaledLossRatio) / 100); 
        }
    }
}