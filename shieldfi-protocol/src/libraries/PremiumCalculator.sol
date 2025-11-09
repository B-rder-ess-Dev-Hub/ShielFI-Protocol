// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @title PremiumCalculator
/// @notice A library for dynamic calculation of insurance premiums.
/// @dev Uses a SCALE_FACTOR of 10000 (100%) for fixed-point math precision.
library PremiumCalculator {
    uint256 private constant SCALE_FACTOR = 10000; 
    uint256 private constant BASE_YEAR_SECONDS = 31536000; // ~1 year in seconds

    /// @notice Calculates the total premium required for a new policy.
    /// @param _riskScore The specific protocol risk score (1-100) from RiskAssessor.
    /// @param _riskFactorMultiplier The historical claims adjustment (e.g., 120 = 1.2x) from RiskMatrix.
    /// @param _coverageAmount The total amount of value being covered (in SHD token units).
    /// @param _coveragePeriod The duration of the policy in seconds.
    /// @return finalPremium The calculated total premium amount in SHD tokens.
    function calculatePremium(
        uint256 _riskScore,
        uint256 _riskFactorMultiplier,
        uint256 _coverageAmount,
        uint256 _coveragePeriod
    ) internal pure returns (uint256 finalPremium) {
        
        // 1. Determine Base Rate from Risk Score (RiskScore/10000)
        // Example: Score 70 -> Base Rate 70 (0.7% per base period)
        // Note: The base rate needs to be converted into a unit like basis points per year. 
        // Let's assume the score (1-100) is used as the base Annual Percentage Rate (APR) in basis points (0.01%)
        // So, a Score of 70 means 70 basis points (0.7% APR).
        uint256 baseAnnualRate = _riskScore * 100; // 70 * 100 = 7000 basis points

        // 2. Adjust Base Rate by Historical Claims Factor
        // Adjusted Annual Rate = Base Rate * Risk Multiplier / 100
        // Example: 7000 * 120 / 100 = 8400 basis points (0.84% APR)
        uint256 adjustedAnnualRate = (baseAnnualRate * _riskFactorMultiplier) / 100;

        // 3. Calculate Premium based on Coverage Amount and Duration
        // Premium = Coverage * (Adjusted Annual Rate / 10000) * (Coverage Period / 1 Year)
        // Rearranging for fixed-point math:
        
        // premium_per_second_scaled = Coverage * Adjusted Annual Rate / BASE_YEAR_SECONDS
        uint256 premiumPerSecondScaled = (_coverageAmount * adjustedAnnualRate) / BASE_YEAR_SECONDS;
        
        // Final Premium = premium_per_second_scaled * Coverage Period / SCALE_FACTOR
        finalPremium = (premiumPerSecondScaled * _coveragePeriod) / SCALE_FACTOR;

        // --- Duration Discount Calculation (The duration factor is already built into the calculation above) ---
        // If you want an additional discount, apply it here.
        // Example: If finalPremium > 1e18 (1 SHD), apply a 10% discount:
        if (finalPremium > 1e18) {
            finalPremium = (finalPremium * 90) / 100; // 10% discount
        }

        return finalPremium;
    }
}