// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

struct Policy {
    uint256 id; // A unique identifier
    address holder; // Who owns this insurance policy
    uint256 coverage; // How much is the insurance payout
    uint256 premium; // How much is the periodical premium payment
    uint8 premium_rate; // How frequent is the premium paid eg monthly, yearly, weekly
    uint256 coverage_period; // How long the insurance is valid for in months
    uint8 status; // either expired, claimed, active
    uint8 risk_cat; // Risk category either SMART_CONTRACT, STABLECOIN, LIQUIDITY_POOL
}

contract PolicyManager {
    error INVALID_PREMIUM_RATE(string _premium_rate);
    error INVALID_POLICY_STATUS(string _status);
    error INVALID_RISK_CATEGORY(string _risk_cat);

    uint256 private s_nextPolicyId = 1;

    // Like constants
    mapping (string => uint8) private s_premium_rates;
    mapping (string => uint8) private s_statuses;
    mapping (string => uint8) private s_risk_categories; // Allowed risk categories

    mapping (address => mapping (uint256 => Policy)) private s_policies;

    constructor () {
        // Initialize premium rates
        s_premium_rates["monthly"] = 1;
        s_premium_rates["bi-weekly"] = 2;
        s_premium_rates["weekly"] = 3;

        // Initialize valid statuses
        s_statuses["active"] = 1;
        s_statuses["claimed"] = 2;
        s_statuses["expired"] = 3;

        // Initialize risk categories
        s_risk_categories["STABLECOIN"] = 1;
        s_risk_categories["SMART_CONTRACT"] = 2;
        s_risk_categories["LIQUIDITY_POOL"] = 3;
    }

    modifier is_valid_premium_rate(string memory _premium_rate) {
        if (s_premium_rates[_premium_rate] == 0) {
            revert INVALID_PREMIUM_RATE(_premium_rate);
        }
        _;
    }

    modifier is_valid_policy_status(string memory _status) {
        if (s_statuses[_status] == 0) {
            revert INVALID_POLICY_STATUS(_status);
        }
        _;
    }

    modifier is_valid_risk_category(string memory _risk_cat) {
        if (s_risk_categories[_risk_cat] == 0) {
            revert INVALID_RISK_CATEGORY(_risk_cat);
        }
        _;
    }

    function get_premium_rates() external pure returns (string[] memory rate_names) {
        // rate_names = new string ; // Allocate memory for 3 items
        rate_names[0] = "monthly";
        rate_names[1] = "bi-weekly";
        rate_names[2] = "weekly";
    }

    function get_risk_categories() external pure returns (string[] memory risk_categories) {
        // risk_categories = new string ; // Allocate memory for 3 items
        risk_categories[0] = "STABLECOIN";
        risk_categories[1] = "SMART_CONTRACT";
        risk_categories[2] = "LIQUIDITY_POOL";
    }

    function createPolicy(uint256 _coverage, uint256 _premium, uint256 _coverage_period, string memory _premium_rate, string memory _risk_cat) public is_valid_premium_rate(_premium_rate) is_valid_risk_category(_risk_cat) returns (uint256) {
        uint256 policyId = s_nextPolicyId;
        s_policies[msg.sender][policyId] = Policy ({
            id: policyId,
            holder: msg.sender,
            coverage: _coverage,
            premium: _premium,
            premium_rate: s_premium_rates[_premium_rate],
            coverage_period: _coverage_period,
            status: 1,
            risk_cat: s_risk_categories[_risk_cat]
        });

        s_nextPolicyId++;

        return policyId;
    }

    function get_policy(uint256 _policyId) public view returns (Policy memory) {
        return s_policies[msg.sender][_policyId];
    }

    function deletePolicy(uint256 _policyId) external {
        Policy storage policy = s_policies[msg.sender][_policyId];

        policy.status = 3;
    }
}