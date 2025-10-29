// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

struct PolicyCoverage {
    uint256 id;
    address payable payoutToken;
    uint256 totalInsuracePay;
    uint256 expires;
}

contract PolicyManager {
    uint256 private s_nextPolicyId = 1;
    mapping (address => mapping (uint256 => PolicyCoverage)) s_policies;

    function createPolicy(address payable _payoutToken, uint256 _insurancePeriod, uint256 _amountPayedForInsurance) public {
        s_policies[msg.sender][s_nextPolicyId] = PolicyCoverage({
            payoutToken: _payoutToken,
            expires: block.timestamp + _insurancePeriod,
            totalInsuracePay: _amountPayedForInsurance,
            id: s_nextPolicyId
        });

        s_nextPolicyId++;
    }

    function deletePolicy(uint256 _policyId) external {
        s_policies[msg.sender][_policyId] = PolicyCoverage({
            payoutToken: payable(address(0)),
            expires: 0,
            totalInsuracePay: 0,
            id: _policyId
        });
    }
}