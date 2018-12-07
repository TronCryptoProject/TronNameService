pragma solidity ^0.4.23;

import {TNSTag} from "./TNSTag.sol";
import {TNSOwnerReverse} from "./TNSOwnerReverse.sol";

contract TNS{
    using TNSTag for TNSTag.TNSTagData;
    struct TagWrapStruct{
        uint keccakTagIdx;
        TNSTag.TNSTagData tagData;
    }
    struct TagData{
        mapping (bytes32 => TagWrapStruct) tagMapping;
        mapping (bytes32 => bytes32) tagKeccackToEncryptedMap;
        bytes32[] keccakTagsList;
        address aliasOwner;
        bool isExist;
    }
    mapping (bytes32 => TagData) aliasMapping;
    mapping (bytes32 => bytes32) aliasKeccackToEncryptedMap;
    TNSOwnerReverse tnsOwnerReverse;

    bytes32 defaultAddress = 0xcfee7c08a98f4b565d124c7e4e28acc52e1bc780e3887db0a02a7d2d5bc66728;
    
    //modifiers
    modifier isOwner(bytes32 aliasName){
        require(msg.sender == aliasMapping[aliasName].aliasOwner, "Only alias owner can call this function");
        _;
    }
    modifier aliasEmpty(bytes32 alias){
        require(alias[0] != 0, "Alias is empty");
        _;
    }
    modifier tagEmpty(bytes32 alias){
        require(alias[0] != 0, "Alias is empty");
        _;
    }


    constructor() public{
        tnsOwnerReverse = new TNSOwnerReverse();
    }

    function addNewAlias(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, TNSTag.TNSTagData tns_tag) private{
        TagData memory tag_data_struct;
        tag_data_struct.aliasOwner = msg.sender;
        tag_data_struct.isExist = true;
        
        aliasMapping[aliasName] = tag_data_struct;
        aliasMapping[aliasName].tagKeccackToEncryptedMap[tagName] = encryptedTag;

        TagWrapStruct memory tag_wrapper = TagWrapStruct({
            keccakTagIdx: aliasMapping[aliasName].keccakTagsList.length,
            tagData: tns_tag
        });
        aliasMapping[aliasName].tagMapping[tagName] = tag_wrapper;
        aliasMapping[aliasName].keccakTagsList.push(tagName);

        //reverse mapping
        tnsOwnerReverse.addOwnerAddress(msg.sender, aliasName);
        aliasKeccackToEncryptedMap[aliasName] = encryptedAlias;
    }

    function addNewTag(bytes32 aliasName, bytes32 tagName, bytes32 encryptedTag,
        TNSTag.TNSTagData tns_tag) private{
        TagWrapStruct memory tag_wrapper = TagWrapStruct({
            keccakTagIdx: aliasMapping[aliasName].keccakTagsList.length,
            tagData: tns_tag
        });
        aliasMapping[aliasName].tagMapping[tagName] = tag_wrapper;
        aliasMapping[aliasName].tagKeccackToEncryptedMap[tagName] = encryptedTag;
        aliasMapping[aliasName].keccakTagsList.push(tagName);
    }

    //tagName would be address of "default" or actual tag name
    function setAlias(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, bytes32 pubAddress) public aliasEmpty(aliasName) tagEmpty(tagName){

        require(pubAddress[0] != 0, "pubAddress is empty");
        
        TNSTag.TNSTagData memory tns_tag;
        tns_tag.isExist = true;
        tns_tag.tagMetaDataStruct.pubAddress = pubAddress;


        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasMapping[aliasName].aliasOwner == msg.sender){
            //alias exists but we are trying to add a tag
            require(isTagAvailable(aliasName, tagName), "Tag is already exists");
            addNewTag(aliasName, tagName, encryptedTag, tns_tag);
        }else{
            revert("Alias is already taken");
        }
    }

    /*If generating new address you wont have default public address for a tag*/
    function setAlias(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, bytes32[] genAddressList) public aliasEmpty(aliasName) tagEmpty(tagName){

        require(genAddressList.length > 0, "genAddressList is empty");

        TNSTag.TNSTagData memory tns_tag;
        tns_tag.isExist = true;
        tns_tag.genAddressStruct.generateAddress = true;
        tns_tag.genAddressStruct.genAddressList = genAddressList; 
        tns_tag.genAddressStruct.numElements = genAddressList.length;

        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasMapping[aliasName].aliasOwner == msg.sender){
            require(isTagAvailable(aliasName, tagName), "Tag is already exists");
            addNewTag(aliasName, tagName, encryptedTag, tns_tag);
        }else{
            revert("Alias is already taken");
        }
       
    }

    //Entire alias & its corresponding tags cannot be deleted but can only be updated
    function deleteAliasTag(bytes32 aliasName, bytes32 tagName) public isOwner(aliasName)
        aliasEmpty(aliasName) tagEmpty(tagName){
        require((tagName != defaultAddress || !isTagAvailable(aliasName, tagName)), "Cannot delete unset tag");
        delete aliasMapping[aliasName].tagMapping[tagName]; 
        delete aliasMapping[aliasName].tagKeccackToEncryptedMap[tagName];

        uint idx_to_remove = aliasMapping[aliasName].tagMapping[tagName].keccakTagIdx;
        bytes32[] storage keccak_tags_list = aliasMapping[aliasName].keccakTagsList;
        keccak_tags_list[idx_to_remove] = keccak_tags_list[--keccak_tags_list.length];
        delete keccak_tags_list[keccak_tags_list.length];

        aliasMapping[aliasName].tagMapping[keccak_tags_list[idx_to_remove]].keccakTagIdx = idx_to_remove;
    }

    function updateAlias(bytes32 aliasName, bytes32 oldEncryptedAlias, bytes32 newAliasName,
        bytes32 newEncryptedAlias) public isOwner(aliasName) aliasEmpty(aliasName){

        require(newAliasName[0] != 0, "New Alias is empty");
        require(isAliasAvailable(newAliasName), "Alias is already taken");
        aliasMapping[newAliasName] = aliasMapping[aliasName];
        delete aliasKeccackToEncryptedMap[oldEncryptedAlias];
        aliasKeccackToEncryptedMap[newAliasName] = newEncryptedAlias;
        delete aliasMapping[aliasName];
        tnsOwnerReverse.updateAlias(msg.sender, aliasName, newAliasName);
    }

    function updatePubAddressForTag(bytes32 aliasName, bytes32 tagName,
        bytes32 newPubAddress) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        require(newPubAddress[0] != 0, "newPubAddress is not set");
        aliasMapping[aliasName].tagMapping[tagName].tagData.setPubAddress(newPubAddress);
    }

    function updateGenAddressFlag(bytes32 aliasName, bytes32 tagName, bool genFlag) public isOwner(aliasName)
        aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.setGenAddressFlag(genFlag);
    }

    function updateGenAddressListReplace(bytes32 aliasName, bytes32 tagName,
        bytes32[] addressList) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.setGenAddressList(addressList);
    }

    function updateGenAddressListAppend(bytes32 aliasName, bytes32 tagName,
        bytes32 newAddress) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.appendGenAddressList(newAddress);
    }

    function updateGenAddressListDelete(bytes32 aliasName, bytes32 tagName, uint idxToRemove) public
        isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.deleteFromGenAddressList(idxToRemove);
    }

    function getGenAddressList(bytes32 aliasName, bytes32 tagName) public view returns(bytes32[]){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressList();
    }

    function getPubAddressForTag(bytes32 aliasName, bytes32 tagName) public view returns(bytes32){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getPubAddress();
    }

    function getGenAddressForTag(bytes32 aliasName, bytes32 tagName, uint idx) public view returns(bytes32){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.useNextGenAddress(idx);
    }

    function getGenAddressFlag(bytes32 aliasName, bytes32 tagName) public view returns(bool){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressFlag();
    }

    function isAliasAvailable(bytes32 aliasName) public view returns(bool){
        if (aliasMapping[aliasName].isExist == false){
            return true;
        }
        return false;
    }
    function isTagAvailable(bytes32 aliasName, bytes32 tagName) public view returns(bool){
        if (aliasMapping[aliasName].tagMapping[tagName].tagData.getExist()){
            return false;
        }
        return true;
    }
    function getAllTagsForAlias(bytes32 aliasName) public view returns(bytes32[]){
        return aliasMapping[aliasName].keccakTagsList;
    }
    function getAliasesForOwner() public view returns(bytes32[]){
        return tnsOwnerReverse.getAllAliasesForOwner(msg.sender);
    }
    function getEncryptedAliasForKeccak(bytes32 aliasName) public view returns(bytes32){
        return aliasKeccackToEncryptedMap[aliasName];
    }
    function getTagDataForTag(bytes32 aliasName, bytes32 tagName) public view returns(bool,bytes32[],bytes32){
        bytes32[] memory gen_list = getGenAddressList(aliasName, tagName);
        bytes32 pub_address = getPubAddressForTag(aliasName, tagName);
        bool gen_flag = getGenAddressFlag(aliasName, tagName);
        return (gen_flag, gen_list, pub_address);
    }
}
