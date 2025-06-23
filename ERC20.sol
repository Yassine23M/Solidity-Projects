// SPDX-License-Identifier: MIT

pragma solidity ^0.8.22;

import "./IERC20.sol";
//something about Safe Math is no longer needed

//why does it need to be marked as abstract 
//because you have implmented all the method 
// this does not have an owner ?????

contract ERC20 is IERC20 {

    // what is the default value of the integers in mapping 

    //think of mapping as a map(K,V)
    // how many tokens each user (wallet) owns 
    //what is the return type here 
    mapping (address => uint256) private _balances;
    //How much one address is allowed to spend on behalf of another
    // tracks allowence is TransferFrom ???
    mapping (address => mapping (address => uint256)) private _allowed;
    //"_" underscroe is sued to signa; private/internal variable, not part of the public interface
    uint private _totalSupply;

    /**
    * @dev total number of tokens in existence 
    */
    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    /**
    @dev return the acount balance of another account with the address _owner
    @param _owner is an address 
    */
    function balanceOf(address _owner) public view returns (uint256 balance){
        // this how you you get the balance of a specific address 
        return _balances[_owner];
    }


    // Trasfer value from one address to another 
    //Transfer event is already declared in the IERC20, so just emit it balances are updated
    //check the address passed is not a zero address 
    //Transfers of 0 value must be treated as a normal transfer and fire the transfer event 
    // the sender is the person calling the contract (confused about is it a wallet or another contract ??
    function transfer(address _to, uint256 _value) public returns (bool success){
        require(_balances[msg.sender] >= _value, "not enough tokens to spend");
        require(_to != address(0), "transfer to zero");
        _balances[msg.sender] -= _value;
        _balances[_to] += _value;
        emit Transfer (msg.sender, _to, _value);
        return true;
    }

     /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through {transferFrom}. This is
     * zero by default.
     *
     * This value changes when {approve} or {transferFrom} are called.
     */
     //return the number of tokens the sender is able to spend on behalf of the onwer 
     //This function is view, meaning it only reads from the state and does not modify it.
    function allowance(address owner, address spender) external view returns (uint256){
        return _allowed[owner][spender];

    }

    // Allow this sender to withdraw from this account upuntil this value 
    //do you have to check if the person calling this function has enough 
    //this sets the value of a spefic authorizer and spender to a specfic value

    /**
    * @dev authorize the address of the spender to withdraw the speccified amount of tokens on behalf of mgs.sender
    *Be ware of  front-running or race conditions in solidity samrt contracts 
    *Beware that changing the allowance using this method might cause the risk of the spender exploiting the old and new allowance. 
    *to unfortunate transaction ordering, where the spender is able to use the previous allowance before the new approva.
    *One possible solution to mitigate the race condition is to first reduce the spender's allowance to zero and then set the new desired value. 
    @ param spender is an address of the spender who will spend tokens
    @ param value is the amount of tokens that should be authorized to be spent
    */
     function approve(address spender, uint256 value) external returns (bool){
        require(spender!=address(0), "transfer to zero");
        _allowed[msg.sender][spender]=value;
        emit Approval(msg.sender, spender, value);
        return true;
     }

     // I yassine autorize that Fatima can spend up to 50 of tokens 

     function transferFrom(address from, address to, uint256 value) external returns (bool){
        //using mapping, instead of calling allowance 
        require(value <= _allowed[from][msg.sender], "Not allowed"); // make sure the sender does not accessed autorized token
        require(value<=_balances[from],"Not allowed"); //make sure the from account has enough tokens
        require(to !=address(0), "transfer to zero");
        _balances[from] -= value;
        _balances[to] += value;
        _allowed[from][msg.sender]-=value; // don't forget to update the allowance
        emit Transfer(from, to, value);
        return true ;
     }

    function increaseAllowance (address spender , uint256 value ) public returns (bool){
        require(spender !=address(0), "transfer to zero");
        _allowed[msg.sender][spender]+=value;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]); //here you are only changing it by a specific amount use _allowed, not value
        return true ;
    }

    function decreaseAllowance (address spender , uint256 value ) public returns (bool){
        require(spender != address(0), "transfer to zero");  
        _allowed[msg.sender][spender]-=value;
        emit Approval(msg.sender, spender, _allowed[msg.sender][spender]); 
        return true;
    }

    /**
    * @dev internal function that mints a specific amount of tokens and assigns it to an account 
    *maybe you can assing it to the contract owner later, but here to any account (internal)
    //what does interanl mean ? can only call it within the contract 
    // it does not return anything ?? why not bool 
    */
    function _mint(address account, uint amount) internal {
        require (account != address(0), "transfer to zero");  
        _totalSupply +=amount;
        _balances[account] += amount ;
        emit Transfer(address(0), account, amount); //here you are simply minting, not minning

    }

   

    /**
    * @dev internal function that burns an amount of tokens from a specfic address
    */
    function _burn(address account , uint256 value) internal {
         require (account != address(0));  
         require(value<=_balances[account], "not allowed"); //can only burn up to the balnce of this account
         _totalSupply -= value;
         _balances[account] -= value ; //this is a way to burn tokens
        emit Transfer (account, address(0), value);
    }

    /**
    *@dev Internal function that allows an approved spender to burn tokens from another account's balance, based on the allowance previously granted.
    *emit an event with the updated approval 
    @param account the account whose tokens will be burnt 
    @param amount The amount that will be burnt 
    */
    function _burnFrom(address account, uint256 amount) internal {
        require(amount<=_allowed[account][msg.sender], "not allowed");
        require(account != address (0),"transfer to zero ");
        _allowed[account][msg.sender] -=  amount;
        emit Approval(account, msg.sender, _allowed[account][msg.sender]);
        _burn(account,amount);
    }
    
}