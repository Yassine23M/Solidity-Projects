// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

contract CrowdFunding {
    //link the address of each contributator to uint amount that they contribuated 
    mapping (address => uint) public contributors;
    address public manager;
    uint public deadline;
    uint public target;
    uint public minContributions;
    uint public raisedAmount;
    uint public noOfContributors;

    // request for spending crowdfundings that must be first approved by voters
    struct Request {
        string description;
        // the address of the person that will receive the requested amount 
        address payable recipient;
        uint value;
        bool isCompleted;
        uint noOfVoters; // number of contributors who voted to approve
        // tracks the number of voters to prevent double voting 
        mapping(address => bool) voters;
    }

    //here the key (uint) functions as a request ID (eg. 1,2,3...)
    mapping(uint=>Request) public requests;
    uint public numRequests;


    // manager decides the target amount, deadline, and min Contributions at the time of deployement 
    constructor(uint _target, uint _deadline, uint _minContributions){
        manager=msg.sender;
        target=_target;
        //seconds from the time of the first block 
        deadline = block.timestamp + _deadline;
        // set Min contributation in Wei 
        minContributions=_minContributions;
    }

    //function allows the contributors to send ether to the smart contract 
    function sendEther() public payable {
        require(block.timestamp < deadline, "Deadline of crowdfunding has already ended");
        require(msg.value>=minContributions,"Minimum Contribution is not met");
        // if the function caller is contributating for the first time, increase the noOfContributors by one
        if(contributors[msg.sender]==0){
            //increase the numner of contributators, 
            noOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        // there is another way to figure out the total ether sent to the conctract 
        // this public, so everyone can see the raisedAmount 
        raisedAmount +=msg.value;
    }

    //function that returns the current balance of the contract in Wei
    // how is this diffeent from using the gatter of raisedAmount to check the current balance
    function getContractBalance() public view returns (uint){
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp > deadline && raisedAmount<target , "can not request refund at this time");
        //make sure that the person intialzing the refund is also a contributator 
        require(contributors[msg.sender]>0,"Only Contributators can request refund");
        address payable user = payable(msg.sender);
        uint amount = contributors[msg.sender];
        //to prevent reentrancy attacks, set their contribution record to 0 before transferring the money,
        contributors[msg.sender]=0;
        user.transfer(amount);
    }

    modifier onlyByManager(){
        require(msg.sender==manager,"Only Manager can approve requests");
        _;

    }

    function createRequest(string memory _description, address payable _recipient, uint value) public onlyByManager{
        Request storage newRequest = requests[numRequests];
        numRequests++;
        newRequest.description=_description;
        newRequest.recipient=_recipient; 
        newRequest.value=value; // in Wei
        //set to false because we intialized a request but it's still not approved 
        newRequest.isCompleted = false;
        newRequest.noOfVoters = 0;
    }


// allow you to vote on the last request, modify so that you can vote on any request using ID/
//can also look at infor of request by ID prior to voting 
    function voteRequest(uint _requestID) public {
        //make sure that voter is a contributator 
        require(contributors[msg.sender]>0,"Only Contributors can vote");
        Request storage thisRequest = requests[_requestID];
        require(thisRequest.voters[msg.sender]==false,"You already Voted");
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }


    // function allows you to process the payment to the recipient once it has got enough votes 
    // is there a way to make it until all contributators have voted first 

    function makePayment(uint _requestID) public onlyByManager{
        require(raisedAmount>target);
        Request storage thisRequest = requests[_requestID];
        require(thisRequest.isCompleted==false, "Already distrubated the amount");
        require(thisRequest.noOfVoters>noOfContributors/2, "Not enough voters to distribute payment");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.isCompleted = true;
    }

}