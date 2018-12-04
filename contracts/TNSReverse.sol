pragma solidity ^0.4.23;
import {TNSModifiers} from "./TNSModifiers.sol"

contract TNSReverse is TNSModifiers{
    mapping (address=>address[]) ownerAliasList;

    function addOwnerAddress(address owner, address alias) public isOwner{
        if (ownerAliasList[owner] != 0x0){
            ownerAliasList[owner].push(alias);
        }else{
            address[] memory tmp_array = new address[](0);
            tmp_array.push(alias);
            ownerAliasList[owner] = tmp_array;
        }
    }

    function getAllAliasesForOwner(address owner) public view return(address[]){
        return ownerAliasList[owner];
    }

    
}