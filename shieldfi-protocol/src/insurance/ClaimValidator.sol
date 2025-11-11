// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.30;

import { Claim, ClaimQueue, CLAIM_STATUS } from "./ClaimQueue.sol";
import { Policy, PolicyManager, RiskCategory, PolicyStatus } from "./PolicyManager.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { RiskData, RiskMatrix } from "./RiskMatrix.sol";

contract ClaimValidator {
    error CLAIM_NOT_FOUND();
    error ClaimNotFound();
    error POLICY_NOT_FOUND();
    error INVALID_POLICY();
    error CLAIM_ALREADY_CHECKED(uint256 claimId, CLAIM_STATUS _status);
    error UNAUTORIZED_CLAIM(address claimant, address policy_holder);

    event CLAIM_APPROVED_AND_PAYOUT_PROCESSED(uint256 claimId, uint256 coverage);

    ClaimQueue private claimQueue;
    PolicyManager private policyManager;
    IERC20 private SHF_Token;
    RiskMatrix private riskMatrix;

    constructor(address _claimQueue, address _policyManager, address _SHF_Token, address _riskMatrix) {
        claimQueue = ClaimQueue(_claimQueue);
        policyManager = PolicyManager(_policyManager);
        SHF_Token = IERC20(_SHF_Token);
        riskMatrix = RiskMatrix(_riskMatrix);
    }

    
    function rejectClaim(uint256 policyId) internal {
        
    }

    function acceptClaim(Claim memory claim, Policy memory claim_policy) internal {
        if (claim.claimant != claim_policy.holder) {
            revert UNAUTORIZED_CLAIM(claim.claimant, claim_policy.holder);
        }

        bool successfulPayout = true; // Replace with this.processPayout(claim_policy)

        if (!successfulPayout) {
            revert("Unable to process Payout");
        }

        claim.status = CLAIM_STATUS.APPROVED;
        claim_policy.status = PolicyStatus.CLAIMED;

        policyManager.setPolicy(claim_policy.id, claim_policy);
        claimQueue.setClaim(claim.id, claim);

        riskMatrix.updateHistoricalDataPerClaimRequest(claim_policy.risk_cat, claim_policy.coverage, true);
        emit CLAIM_APPROVED_AND_PAYOUT_PROCESSED(claim.id, claim_policy.coverage);
    }

    function processPayout(Policy memory policy) internal {
        SHF_Token.transfer(policy.holder, policy.coverage);
    }

    function validateClaim(uint256 claimId) public {
        Claim memory claim = claimQueue.getClaim(claimId);

        if (claim.status != CLAIM_STATUS.PENDING) {
            revert CLAIM_ALREADY_CHECKED(claim.id, claim.status);
        }

        Policy memory claim_policy = policyManager.get_policy(claim.policy);

        if (claim_policy.risk_cat == RiskCategory.STABLECOIN) {
            // Implement the stablecoin depeg check, so we'll check the price of the token now and see if the price difference dropped a lot
            uint256 initialPrice = claim_policy.initial_stable_coin_price; // initial price of the stable coin
            uint256 expectedPriceAfterA20PercentDrop = initialPrice - ((initialPrice * 20) / 100);

            uint256 currentPrice = 192381247124; // Default value, to be fetched from the price feed

            if (currentPrice <= expectedPriceAfterA20PercentDrop) { // If there's more than a 20% drop in the price of the stable coin
                // Mark the claim as valid
                // this.acceptClaim(claim);
            } else {
                // reject Claim
                // this.rejectClaim(claim.id);
            }
        } else if (claim_policy.risk_cat == RiskCategory.SMART_CONTRACT) {
            // To-Do: Ummm, I don't know how to implement this yet
        } else {
            // To-Do: Ummm, I don't know how to implement this yet
        }
    }
}