// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import { Policy } from 

interface IPolicy {
    function get_policy(uint256 _policyId) external view returns (Policy memory);
}

struct Claim {
    uint256 id;
    uint256 status;
    uint256 policy;
    uint256 priority;
}

contract ClaimQueue {
    error POLICY_NOT_FOUND(uint256 policyId);

    event NEW_CLAIM_CREATED(uint256 indexed _claimId, uint256 indexed _policy);

    uint256 s_highestPriority;
    uint256 s_nextClaimId = 1;
    IPolicy policyManager;
    Claim[] claims;

    constructor (address _policyManagerAddress) {
        policyManager = IPolicy(_policyManagerAddress);
    }


    function submitClaim(uint256 _policyId) public returns (uint256) {
        Policy memory policy = policyManager.get_policy(_policyId);
        uint256 priority = 0;
        uint256 claim_id = s_nextClaimId;

        if (policy.id == 0) {
            revert POLICY_NOT_FOUND(_policyId);
        }

        for (uint256 i = 0; i < claims.length; i++) 
        {
            Claim memory claim = claims[i];
            Policy memory claims_policy = policyManager.get_policy(claim.policy);
            if (policy.coverage > claims_policy.coverage) {
                priority = claim.priority + 1;
                s_highestPriority = priority;
            }
        }

        Claim memory new_claim = Claim({
            id: claim_id,
            status: 1,
            policy: _policyId,
            priority: priority
        });

        claims.push(new_claim);

        // Emit claim created event
        emit NEW_CLAIM_CREATED(new_claim.id, policy.id);
        s_nextClaimId += 1;

        return new_claim.id;
    }

    function getClaims() public view returns (Claim[] memory) {
        return claims;
    }
}