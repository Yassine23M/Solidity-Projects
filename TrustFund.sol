// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract TrustFund{

    address public parent; 

     //this contract is dsigned for multiple beneficiaries
    struct Beneficiary{
        uint amount;
        uint maturity; 
        bool withdrawn; 
    }

    constructor() payable {
        parent=msg.sender;
    }

    event Beneficiaradded(address beneficiary, uint maturity, uint amount);
    event Withdrawal(address beneficiary , uint amount);

    mapping (address => Beneficiary) public  beneficiaries; 

    modifier onlyParent{
        require(msg.sender==parent,"Only parent can addd beneficiaries");
        require(msg.sender!=address(0),"No address provided!");
        _;
    }
    /**
    @dev allow parent to add new beneficiaries to the trust fund 
    @param _beneficiary address of beneficiary
    @param _maturityTime the maturity time for the beneficiary in seconds starting from today's timestamp 
    */

    function addBeneficiary (address _beneficiary, uint _maturityTime) external payable onlyParent  {
        // assume that if the amount is zero, then the beneficiary was not added to the trust 
        require(beneficiaries[_beneficiary].amount==0,"Beneficiary exists");
        beneficiaries[_beneficiary] = Beneficiary(msg.value, block.timestamp + _maturityTime, false);
        emit Beneficiaradded(_beneficiary, beneficiaries[_beneficiary].maturity, msg.value);
    }

    /**
    @dev allow beneficiary to withdraw all the funds at the time of muturity 
    */
    function withdraw () external {
        // Use 'storage' to get a direct reference to the beneficiary struct in contract storage (not a copy)
        // so any changes made to "beneficiary" will update the actual data on-chain
        Beneficiary storage  b = beneficiaries[msg.sender];
        require(b.maturity<=block.timestamp,"Can not withdraw before maturity");
        require(b.amount>0, "No funds to withdraw");    
        require(!b.withdrawn, "Already withdrawn");
        // Prevents double withdrawals.
        b.withdrawn = true;
        emit Withdrawal(msg.sender, b.amount);
        payable(msg.sender).transfer(b.amount);
    }

}