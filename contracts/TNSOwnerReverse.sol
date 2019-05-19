pragma solidity ^0.4.23;

contract TNSOwnerReverse{
    mapping (address=>bytes32[]) ownerAliasList; //include a map of keccak alias to list idx

    function addOwnerAddress(address aliasOwner, bytes32 alias) public{
        ownerAliasList[aliasOwner].push(alias);
    }

    function getAllAliasesForOwner(address aliasOwner) public view returns(bytes32[]){
        return ownerAliasList[aliasOwner];
    }

    function updateAlias(address aliasOwner, bytes32 oldAlias, bytes32 newAlias) public{
        for(uint i = 0; i < ownerAliasList[aliasOwner].length; i++){
            if (ownerAliasList[aliasOwner][i] == oldAlias){
                ownerAliasList[aliasOwner][i] = newAlias;
                break;
            }
        }
    }
    
}