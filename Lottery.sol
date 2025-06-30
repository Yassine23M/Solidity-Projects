// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;


contract Lottery{

    address public admin;
    address payable [] public participants;

    event participantsAdded (address sender);
    event winnerSelected(address winner);

    constructor(){
        admin=msg.sender;
    }

    // participants must spend exactly 0.1 ether to enter the lottery 
    //participant with the same wallet address can not enter the lottery more than once 
    function enter () external payable {
        require(msg.value==0.1 ether, "Fee is 0.1 eth to enter lottery");
        // check if wallet address already entered the lottery 
        for (uint i = 0; i<participants.length; i++){
            if((participants[i]==msg.sender)){
                revert("Already entered lottery");
            }
        }
        
        // create a new address payable struct and add it to the array of participants 
        participants.push(payable(msg.sender));
        emit participantsAdded(msg.sender);
    }

    function getBalance() public view returns (uint){
        require(msg.sender==admin);
        //address this give the address of this coctract itself 
        //.balance gives the amount of ether held by the contract in Wei
        return address(this).balance;
    }

    // function that generates a random number using Keccak256 hash function 
    function random() internal view returns (uint){
        return uint(keccak256(abi.encodePacked(block.prevrandao, block.timestamp, participants.length)));
    }

    //function that allows admin to declare the winner and trasnsfer the balance 
    function winner () external payable {
           require(msg.sender==admin, "Only admin can decalre the winner");
           // there must at least be 3 participants in the lottery 
           require(participants.length>=3, "Not enough players");
           address payable Winner;
           uint r = random();
           uint index = (r % participants.length);
           Winner = participants[index];
           // transfer the balance of all participants to the winner 
           Winner.transfer(getBalance());
           emit winnerSelected(Winner);
    }

}