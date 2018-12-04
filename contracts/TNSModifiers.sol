pragma solidity ^0.4.23;

contract TNSModifiers{
    address owner;
    constructor() public {
        owner = msg.sender;
    }

    modifier isOwner(){
        require(msg.sender == owner, "Only contract owner can call this function");
        _;
    }

    modifier aliasEmpty(alias){
        require(alias != address(0), "Alias is empty");
        _;
    }
    modifier tagEmpty(alias){
        require(alias != address(0), "Alias is empty");
        _;
    }
}