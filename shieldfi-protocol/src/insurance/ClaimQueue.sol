// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import { Policy, PolicyManager } from "./PolicyManager.sol";

enum CLAIM_STATUS {
    PENDING,
    APPROVED,
    DENIED
}
struct Claim {
    uint256 id;
    CLAIM_STATUS status;
    uint256 policy;
    uint256 priority;
    address claimant;
    uint256 amount;
    uint256 submissionTime;
}

contract ClaimQueue {
    error POLICY_NOT_FOUND(uint256 policyId);
    error UNAUTHORIZED_CLAIM();

    event NEW_CLAIM_CREATED(uint256 indexed _claimId, uint256 indexed _policy);
    event CLAIM_UPDATED(uint256 claimId, CLAIM_STATUS indexed _newStatus);

    uint256 private s_highestPriority;
    uint256 private s_nextClaimId = 1;
    PolicyManager private policyManager;
    mapping (uint256 => Claim) private s_claims;
    uint256[] private allClaimIds;

    constructor (address _policyManagerAddress) {
        policyManager = PolicyManager(_policyManagerAddress);
    }


    function submitClaim(uint256 _policyId, uint256 _claimAmount) public returns (uint256) {
        // No checks

        // Implement
        Policy memory policy = policyManager.get_policy(_policyId);
        uint256 priority = 0;
        uint256 claim_id = s_nextClaimId;

        if (policy.id == 0) {
            revert POLICY_NOT_FOUND(_policyId);
        }

        for (uint256 i = 0; i < allClaimIds.length; i++) 
        {
            Claim memory claim = s_claims[i];
            Policy memory claims_policy = policyManager.get_policy(claim.policy);
            if (policy.coverage > claims_policy.coverage) {
                priority = claim.priority + 1;
                s_highestPriority = priority;
            }
        }

        s_claims[claim_id] = Claim({
            id: claim_id,
            status: CLAIM_STATUS.PENDING,
            policy: _policyId,
            priority: priority,
            claimant: msg.sender,
            amount: _claimAmount,
            submissionTime: block.timestamp
        });

        // Emit claim created event
        emit NEW_CLAIM_CREATED(s_claims[claim_id].id, policy.id);
        s_nextClaimId += 1;

        return s_claims[claim_id].id;
    }

    function updateClaimStatus(uint256 _claimId, CLAIM_STATUS _status) external {
        Claim storage claim = s_claims[_claimId];

        // Check
        if (claim.claimant != msg.sender) {
            revert UNAUTHORIZED_CLAIM();
        }

        claim.status = _status;

        emit CLAIM_UPDATED(_claimId, _status);
    }

    function getNextClaimToProcess() external view returns(uint256) {
        Claim memory _claim = s_claims[0];

        for (uint256 i = 1; i < allClaimIds.length; i++) 
        {
            Claim memory claim = s_claims[i];
            if (claim.priority > _claim.priority) {
                _claim = claim;
            } else if (claim.priority == _claim.priority) {
                if(claim.submissionTime < _claim.submissionTime) {
                    _claim = claim;
                }
            }
        }

        return _claim.id;
    }

    // function getClaims() public view returns (Claim[] memory) {
    //     return s_claims;
    // }
}