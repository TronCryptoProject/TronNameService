pragma solidity ^0.4.23;

contract BaseConfig{
    address internal mainOwner;

    modifier isMainOwner(){
        require(mainOwner != address(0) && msg.sender == mainOwner, "Only contract owner is permissioned");
        _;
    }

    modifier notEmptyAddr(address addr){
        require(addr != address(0), "Address is empty");
        _;
    }
    modifier notEmptyBytes32(bytes32 bytes_val){
        require(bytes_val != bytes32(0), "Bytes32 is empty");
        _;
    }
    constructor() public{
        mainOwner = msg.sender;
    }

    function transferOwner(address newOwner) notEmptyAddr(newOwner) isMainOwner public{
        mainOwner = newOwner;
    }
}