// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8;

contract ShielFI {
    error InvalidInsuranceType(uint256 _insuranceType);

    mapping (string => uint256) private s_INSURANCE_AVAILABILITY_OPTIONS;

    constructor() {
        s_INSURANCE_AVAILABILITY_OPTIONS["stable_coin_depeg"] = 1;
    }

    modifier is_valid_insurance_type(string memory _insuranceType) {
        if (s_INSURANCE_AVAILABILITY_OPTIONS[_insuranceType] == 0) {
            revert InvalidInsuranceType(s_INSURANCE_AVAILABILITY_OPTIONS[_insuranceType]);
        }
        _;
    }

    function get_insurance_options() public view {}

    function get_insurance_amount(uint256 _period, address) public view {

    }

    function purchase_insurance(string memory _insuranceType, address _tokenContract) public is_valid_insurance_type(_insuranceType) {
        
    }

    function name() public {
        
    }
}