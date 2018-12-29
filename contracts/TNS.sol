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
    event StateUpdated(address indexed _from);
    event StateAliasUpdated(address indexed _from, bytes32 _alias); //fetch update for specific alias

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
    function setAliasStatic(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, address pubAddress) public aliasEmpty(aliasName) tagEmpty(tagName){

        require(pubAddress != 0x0, "pubAddress is empty");
        
        TNSTag.TNSTagData memory tns_tag;
        tns_tag.isExist = true;
        tns_tag.tagMetaDataStruct.pubAddress = pubAddress;


        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasMapping[aliasName].aliasOwner == msg.sender){
            //alias exists but we are trying to add a tag
            require(isTagAvailable(aliasName, tagName), "Tag already exists");
            addNewTag(aliasName, tagName, encryptedTag, tns_tag);
        }else{
            revert("Alias is already taken");
        }
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    /*If generating new address you wont have default public address for a tag*/
    function setAliasGenerated(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, address[] genAddressList) public aliasEmpty(aliasName) tagEmpty(tagName){

        require(genAddressList.length > 0, "genAddressList is empty");

        TNSTag.TNSTagData memory tns_tag;
        tns_tag.isExist = true;
        tns_tag.genAddressStruct.generateAddress = true;
        tns_tag.genAddressStruct.genAddressList = genAddressList; 
        tns_tag.genAddressStruct.numElements = genAddressList.length;

        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasMapping[aliasName].aliasOwner == msg.sender){
            require(isTagAvailable(aliasName, tagName), "Tag already exists");
            addNewTag(aliasName, tagName, encryptedTag, tns_tag);
        }else{
            revert("Alias is already taken");
        }
       emit StateAliasUpdated(msg.sender, aliasName);
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
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateAlias(bytes32 aliasName, bytes32 oldEncryptedAlias, bytes32 newAliasName,
        bytes32 newEncryptedAlias) public isOwner(aliasName) aliasEmpty(aliasName){

        require(newAliasName[0] != 0, "New Alias is empty");
        require(isAliasAvailable(newAliasName), "Alias is already taken");
        aliasMapping[newAliasName] = aliasMapping[aliasName];
        delete aliasKeccackToEncryptedMap[aliasName];
        aliasKeccackToEncryptedMap[newAliasName] = newEncryptedAlias;
        delete aliasMapping[aliasName];
        tnsOwnerReverse.updateAlias(msg.sender, aliasName, newAliasName);

        emit StateUpdated(msg.sender);
    }

    function updateTag(bytes32 aliasName, bytes32 tagName, bytes32 oldEncryptedTag,
        bytes32 newTagName, bytes32 newEncryptedTag) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){

        require(newTagName[0] != 0, "New tag is empty");
        require(isTagAvailable(aliasName, newTagName), "Tag already exists");
        aliasMapping[aliasName].tagMapping[newTagName] = aliasMapping[aliasName].tagMapping[tagName];

        uint keccak_idx = aliasMapping[aliasName].tagMapping[tagName].keccakTagIdx;
        aliasMapping[aliasName].keccakTagsList[keccak_idx] = newTagName;

        aliasMapping[aliasName].tagKeccackToEncryptedMap[newTagName] = newEncryptedTag;
        delete aliasMapping[aliasName].tagKeccackToEncryptedMap[tagName];
        delete aliasMapping[aliasName].tagMapping[tagName];

        emit StateUpdated(msg.sender);
    }

    function updatePubAddressForTag(bytes32 aliasName, bytes32 tagName,
        address newPubAddress) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        require(newPubAddress != 0x0, "newPubAddress is not set");
        if (newPubAddress == 0x0){
            if (aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressFlag() == false){
                revert("In order to unset public address, auto-generated addresses must be on and have rotating addresses. Only one option can be on at any given time.");
            }
        }
        aliasMapping[aliasName].tagMapping[tagName].tagData.setPubAddress(newPubAddress);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressFlag(bytes32 aliasName, bytes32 tagName, bool genFlag) public isOwner(aliasName)
        aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.setGenAddressFlag(genFlag);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListReplace(bytes32 aliasName, bytes32 tagName,
        address[] addressList) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.setGenAddressList(addressList);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListAppend(bytes32 aliasName, bytes32 tagName,
        address newAddress) public isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){

        uint num_elems = aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressListLen();
        require(num_elems < 20, "You can only store up to 20 addresses in order to obey gas limit");
        aliasMapping[aliasName].tagMapping[tagName].tagData.appendGenAddressList(newAddress);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListDelete(bytes32 aliasName, bytes32 tagName, uint idxToRemove) public
        isOwner(aliasName) aliasEmpty(aliasName) tagEmpty(tagName){
        aliasMapping[aliasName].tagMapping[tagName].tagData.deleteFromGenAddressList(idxToRemove);
        emit StateAliasUpdated(msg.sender, aliasName);
    }


    //GETTERS

    //Only the owner can get the address list
    function getGenAddressList(bytes32 aliasName, bytes32 tagName) public view isOwner(aliasName) returns(address[]){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressList();
    }

    function getGenAddressListLen(bytes32 aliasName, bytes32 tagName) public view returns(uint){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getGenAddressListLen();
    }

    function getPubAddressForTag(bytes32 aliasName, bytes32 tagName) public view returns(address){
        return aliasMapping[aliasName].tagMapping[tagName].tagData.getPubAddress();
    }

    function getGenAddressForTag(bytes32 aliasName, bytes32 tagName, uint idx) public view returns(address){
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
    function getAliasesForOwner(address ownerAddress) public view returns(bytes32[]){
        return tnsOwnerReverse.getAllAliasesForOwner(ownerAddress);
    }
    function getEncryptedAliasForKeccak(bytes32 aliasName) public view returns(bytes32){
        return aliasKeccackToEncryptedMap[aliasName];
    }
    function getEncryptedTagForKeccak(bytes32 aliasName, bytes32 tagName) public view returns(bytes32){
        return aliasMapping[aliasName].tagKeccackToEncryptedMap[tagName];
    }

    function getAliasOwner(bytes32 aliasName) public view returns(address){
        return aliasMapping[aliasName].aliasOwner;
    }

    function getTagDataForTag(bytes32 aliasName, bytes32 tagName) public view returns(bool,address[],address){
        address[] memory gen_list = getGenAddressList(aliasName, tagName);
        address pub_address = getPubAddressForTag(aliasName, tagName);
        bool gen_flag = getGenAddressFlag(aliasName, tagName);
        return (gen_flag, gen_list, pub_address);
    }
}
