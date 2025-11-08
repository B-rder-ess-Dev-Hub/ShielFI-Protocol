// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

enum RISK_CATEGORY {
    SMART_CONTRACT,
    STABLECOIN,
    LIQUIDITY_POOL
}

struct RiskData {
    uint256 base_score; // The base score for a policy to fit into this risk category
    uint256 no_of_claims; // Number of claims that have been requested
    uint256 total_payouts; // Amount of payouts that has been sent for all policies under this category
    uint256 total_premium; // Amount of premiums that haas been paid into this category
    uint256 risk_factor;
}

contract RiskMatrix {
    error BASE_SCORE_OUT_OF_RANGE();

    event BaseScoreUpdated(RISK_CATEGORY indexed category, uint256 newScore);
    event HistoricalDataUpdated(RISK_CATEGORY indexed category, uint256 newClaims, uint256 newPayouts, uint256 newPremiums);

    mapping(RISK_CATEGORY => RiskData) public s_riskMatrix;
    
    constructor() {
        // Initialize base scores (e.g., 50 for a mid-level risk on a 100-point scale)
        s_riskMatrix[RISK_CATEGORY.SMART_CONTRACT].base_score = 40;
        s_riskMatrix[RISK_CATEGORY.LIQUIDITY_POOL].base_score = 60;
        s_riskMatrix[RISK_CATEGORY.STABLECOIN].base_score = 70;
    }

    function updateBaseScore(RISK_CATEGORY _risk_category, uint256 _new_score) external {
        // Check
        if (_new_score > 100 ) {
            revert BASE_SCORE_OUT_OF_RANGE();
        }

        // Implement
        s_riskMatrix[_risk_category].base_score = _new_score;

        // Emit
        emit BaseScoreUpdated(_risk_category, _new_score);
    }

    function updateHistoricalDataPerClaimRequest(RISK_CATEGORY _category, uint256 _claimValue, bool _isPayout) external {
        // No checks

        // Implement
        RiskData storage risk = s_riskMatrix[_category];
        risk.no_of_claims++;

        if (_isPayout) {
            risk.total_payouts += _claimValue;
        }

        // Emit
        emit HistoricalDataUpdated(_category, risk.no_of_claims, risk.total_payouts, risk.total_premium);
    }
    
    function updateHistoricalDataPerPremiumPaid(RISK_CATEGORY _category, uint256 _premium_value) external {
        // No checks

        // Implement
        RiskData storage risk = s_riskMatrix[_category];
        risk.total_premium += _premium_value;

        // Emit
        emit HistoricalDataUpdated(_category, risk.no_of_claims, risk.total_payouts, risk.total_premium);
    }

    /// @notice Calculates and returns the current risk factor for a category.
    /// @dev This is a simplified example; the actual calculation would be more complex.
    /// @param _category The risk category.
    /// @return The calculated risk factor (e.g., 100 = 1.0 multiplier).
    function calculateRiskFactor(RISK_CATEGORY _category) public view returns (uint256) {
        RiskData storage risk = s_riskMatrix[_category];

        // 1. If no claims or no premiums collected, return the neutral factor (1.0x)
        if (risk.total_premium == 0) {
            return 100; 
        }

        // 2. Calculate the Actuarial Loss Ratio (Scaled)
        // Scale by 100 to convert to a percentage-like integer (e.g., 7500 for a 0.75 Loss Ratio)
        // Scaling by 10000 ensures high precision:
        uint256 scaledLossRatio = (risk.total_payouts * 10000) / risk.total_premium; 
        
        // 3. Determine the Risk Factor Multiplier (Centered around 100 = 1.0x)
        // Loss Ratio of 1.0 (100% loss) means payouts = premiums. The factor should be neutral/slightly high.
        // Loss Ratio of 0.75 (7500 scaled) means profit. The factor should be low.
        
        // Example Formula: Adjust the base 100 factor based on how far the Loss Ratio is from a sustainable target (e.g., 80% loss ratio)
        uint256 targetRatio = 8000; // Assuming the protocol aims for a maximum 80% loss ratio (20% profit)
        
        // If the actual ratio is > target, factor goes up. If < target, factor goes down.
        if (scaledLossRatio > targetRatio) {
            // High loss: factor goes > 100.
            // Example: Loss Ratio 10000 (1.0) is 2000 (0.2) higher than target. Factor increases.
            return 100 + (scaledLossRatio - targetRatio) / 100; // Arbitrary scale for adjustment
        } else {
            // Low loss: factor goes < 100.
            // Example: Loss Ratio 6000 (0.6) is 2000 (0.2) lower than target. Factor decreases.
            return 100 - (targetRatio - scaledLossRatio) / 100; // Arbitrary scale for adjustment
        }
    }
}