// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

enum RiskCategory {
    SMART_CONTRACT,
    STABLECOIN,
    LIQUIDITY_POOL
}

enum PolicyStatus {
    ACTIVE,
    CLAIMED,
    EXPIRED,
    PENDING,
    DELETED
}

struct Policy {
    uint256 id; // A unique identifier
    address holder; // Who owns this insurance policy
    uint256 coverage; // How much is the insurance payout
    uint256 premium; // How much is the periodical premium payment
    uint256 premium_rate; // How much is the premium paid
    uint256 coverage_period; // How long the insurance is valid for in seconds
    PolicyStatus status; // either expired, claimed, active
    RiskCategory risk_cat; // Risk category either SMART_CONTRACT, STABLECOIN, LIQUIDITY_POOL
    uint256 start_time; // When the policy is created
    uint256 end_time; // When the policy expires
    uint256 last_premium_payment; // When the last premium was paid
}

contract PolicyManager {
    event POLICY_CREATED(uint256 policyId, address indexed holder, uint256 coverageAmount, PolicyStatus status);
    event POLICY_STATUS_UPDATED(uint256 policyId, PolicyStatus newStatus);

    // Constants
    uint256 private s_nextPolicyId = 1;
    uint256[] private allPolicyIds; 

    // Mapping from policy ID to policy details
    mapping (uint256 => Policy) private s_policies;

    function createPolicy(uint256 _coverage, uint256 _premium, uint256 _coverage_period, uint256 _premium_rate, RiskCategory _risk_cat) public  returns (uint256) {
        // No checks

        // Implement block
        uint256 policyId = s_nextPolicyId;

        uint256 start_time = block.timestamp;
        uint256 end_time = start_time + _coverage_period;

        s_policies[policyId] = Policy ({
            id: policyId,
            holder: msg.sender,
            coverage: _coverage,
            premium: _premium,
            premium_rate: _premium_rate,
            coverage_period: _coverage_period,
            status: PolicyStatus.PENDING,
            risk_cat: _risk_cat,
            start_time: start_time,
            end_time: end_time,
            last_premium_payment: 0
        });

        allPolicyIds.push(policyId);

        s_nextPolicyId++;

        // Emit
        emit POLICY_CREATED(policyId, msg.sender, _coverage, PolicyStatus.PENDING);

        return policyId;
    }

    function get_policy(uint256 _policyId) public view returns (Policy memory) {
        return s_policies[_policyId];
    }

    function update_policy(uint256 _policyId, PolicyStatus _status) external returns (bool) {
        Policy storage policy = s_policies[_policyId];
        require(policy.holder != address(0), "PolicyManager: Invalid policy ID");

        policy.status = _status;

        emit POLICY_STATUS_UPDATED(_policyId, _status);

        return true;
    }

    function deletePolicy(uint256 _policyId) external {
        Policy storage policy = s_policies[_policyId];

        policy.status = PolicyStatus.DELETED;
    }
}