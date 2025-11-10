// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

/// @title PremiumCalculator
/// @notice A library for dynamic calculation of insurance premiums.
/// @dev Uses a SCALE_FACTOR of 10000 (100%) for fixed-point math precision.
library PremiumCalculator {
    uint256 private constant SCALE_FACTOR = 10000; 
    uint256 private constant BASE_YEAR_SECONDS = 31536000; // Approx 1 year in seconds

    /// @notice Calculates the total premium required for a new policy.
    /// @param _riskScore The specific protocol risk score (1-100) from RiskAssessor.
    /// @param _riskFactorMultiplier The historical claims adjustment (e.g., 120 = 1.2x) from RiskMatrix.
    /// @param _coverageAmount The total amount of value being covered (in SHD token units).
    /// @param _coveragePeriod The duration of the policy in seconds.
    /// @return finalPremium The calculated total premium amount in SHD tokens.
    function calculatePremium(
        uint256 _riskScore,
        uint256 _riskFactorPerRiskCategory,
        uint256 _coverageAmount,
        uint256 _coveragePeriod,
        uint256 _baseScorePerRiskCategory,
    ) internal pure returns (uint256 finalPremium) {
        
        // 1. Determine Base Rate from Risk Score (RiskScore/10000)
        // Example: Score 70 -> Base Rate 70 (0.7% per base period)
        // Note: The base rate needs to be converted into a unit like basis points per year. 
        // Let's assume the score (1-100) is used as the base Annual Percentage Rate (APR) in basis points (0.01%)
        // So, a Score of 70 means 70 basis points (0.7% APR).
        uint256 baseAnnualRate =( _riskScore + (_baseScorePerRiskCategory / 5)) * 100; // 70 * 100 = 7000 basis points making the baseriskscore hold a 20% extra weight

        // 2. Adjust Base Rate by Historical Claims Factor
        // Adjusted Annual Rate = Base Rate * Risk Multiplier / 100
        // Example: 7000 * 120 / 100 = 8400 basis points (0.84% APR)
        uint256 adjustedAnnualRate = (baseAnnualRate * _riskFactorPerRiskCategory) / 100;

        // 3. Calculate Premium based on Coverage Amount and Duration
        // Premium = Coverage * (Adjusted Annual Rate / 10000) * (Coverage Period / 1 Year)
        // Rearranging for fixed-point math:
        
        // premium_per_second_scaled = Coverage * Adjusted Annual Rate / BASE_YEAR_SECONDS
        uint256 premiumPerSecondScaled = (_coverageAmount * adjustedAnnualRate) / BASE_YEAR_SECONDS;
        
        if (_coveragePeriod > BASE_YEAR_SECONDS) {
            // Apply a discount for longer coverage periods
            // For example, a 5% discount for coverage > 1 year
            
            uint256 discountFactor = 5; // 5% discount by default
            premiumPerSecondScaled = (premiumPerSecondScaled * (100 - discountFactor)) / 100;
        } else if (_coveragePeriod < BASE_YEAR_SECONDS) {
            // Apply a surcharge for shorter coverage periods
            // For example, a 5% surcharge for coverage < 1 year
            
            uint256 surchargeFactor = 5; // 5% surcharge by default
            premiumPerSecondScaled = (premiumPerSecondScaled * (100 + surchargeFactor)) / 100;
        }
        
        // Final Premium = premium_per_second_scaled * Coverage Period / SCALE_FACTOR
        finalPremium = (premiumPerSecondScaled * _coveragePeriod) / SCALE_FACTOR;

        return finalPremium;
    }
}