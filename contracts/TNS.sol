pragma solidity ^0.4.23;

import {TNSModifiers} from "./TNSModifiers.sol"
import {TNSTag} from "./TNSTag.sol"

contract TNS is TNSModifiers{
    struct TagData{
        mapping (address => TNSTag) public tagMapping;
        address aliasOwner;
    }
    mapping (address => TagData) public aliasMapping;
    address constant defaultAddress = 0xcfee7c08a98f4b565d124c7e4e28acc52e1bc780e3887db0a02a7d2d5bc66728;

    //tagName would be address of "default" or actual tag name
    function setAlias(address aliasName, address tagName, address pubAddress)
        public isOwner, aliasEmpty, tagEmpty{

        require(pubAddress != address(0), "pubAddress is empty");
        require(isAliasAvailable(aliasName), "Alias is already taken");

        TagData memory tag_data_struct;
        tag_data_struct.aliasOwner = owner;

        TNSTag memory tns_tag = new TNSTag();
        tns_tag.setPubAddress(pubAddress);
        tag_data_struct.tagMapping[tagName] = tns_tag;
        aliasMapping[aliasName] = tag_data_struct;
    }

    /*If generating new address you wont have default public address for a tag*/
    function setAlias(address aliasName, address tagName, address[] genAddressList)
        public isOwner, aliasEmpty, tagEmpty{
        require(genAddressList.length > 0, "genAddressList is empty");
        require(isAliasAvailable(aliasName), "Alias is already taken");

        TagData memory tag_data_struct;
        tag_data_struct.aliasOwner = owner;

        TNSTag memory tns_tag = new TNSTag();
        tns_tag.setGenAddressList(genAddressList);
        tag_data_struct.tagMapping[tagName] = tns_tag;
        aliasMapping[aliasName] = tag_data_struct;
    }

    //Entire alias & its corresponding tags cannot be deleted but can only be updated
    function deleteAlias(address aliasName, address tagName) public isOwner, aliasEmpty, tagEmpty{
        require(tagName != defaultAddress, "Cannot delete unset tag");
        delete aliasMapping[aliasName].tagMapping[tagName]; 
    }

    function updateAlias(address aliasName, address newAliasName) public isOwner, aliasEmpty{
        require(newAliasName != address(0), "New Alias is empty");
        require(isAliasAvailable(newAliasName), "Alias is already taken");
        aliasMapping[newAliasName] = aliasMapping[aliasName];
        delete aliasMapping[aliasName];
    }

    function updateTagPubAddress(address aliasName, address tagName,
        address newPubAddress) public isOwner, aliasEmpty, tagEmpty{
        require(newPubAddress != address(0), "newPubAddress is not set");
        aliasMapping[aliasName].tagMapping[tagName].setPubAddress(newPubAddress);
    }

    function updateGenAddressFlagStop(address aliasName, address tagName) public isOwner,aliasEmpty,tagEmpty{
        aliasMapping[aliasName].tagMapping[tagName].setGenAddressFlag(false);
    }

    function updateGenAddressListReplace(address aliasName, address tagName,
        address[] addressList) public isOwner,aliasEmpty,tagEmpty{
        aliasMapping[aliasName].tagMapping[tagName].setGenAddressList(addressList);
    }

    function updateGenAddressListAppend(address aliasName, address tagName,
        address newAddress) public isOwner,aliasEmpty,tagEmpty{
        aliasMapping[aliasName].tagMapping[tagName].appendGenAddressList(newAddress);
    }

    function updateGenAddressListDelete(address aliasName, address tagName, uint idxToRemove) public
        isOwner, aliasEmpty, tagEmpty{
        aliasMapping[aliasName].tagMapping[tagName].deleteFromGenAddressList(idxToRemove);
    }

    function getGenAddressList(address aliasName, address tagName) public view returns(address[]){
        return aliasMapping[aliasName].tagMapping[tagName].getGenAddressList();
    }

    function getPubAddressForAlias(address aliasName, address tagName) public view returns(address){
        return aliasMapping[aliasName].tagMapping[tagName].getPubAddress();
    }

    function getGenAddressForAlias(address aliasName, address tagName, uint idx) public view returns(address){
        return aliasMapping[aliasName].tagMapping[tagName].useNextGenAddress(idx);
    }

    function isAliasAvailable(address aliasName) public view returns(bool){
        if (aliasMapping[aliasName] == 0){
            return true;
        }
        return false;
    }

    //reverse look-up
    /*function getAlias(bytes32 aliasName, bytes32 tagName) view public returns (address aliasAddress) {
        
    }*/
}
