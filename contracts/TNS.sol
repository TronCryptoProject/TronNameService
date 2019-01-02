pragma solidity ^0.4.23;

import {TNSTag} from "./TNSTag.sol";
import {TNSOwnerReverse} from "./TNSOwnerReverse.sol";

contract TNS{
    using TNSTag for TNSTag.TNSTagData;
    struct TagWrapStruct{
        TNSTag.TNSTagData tnsTagData;
        bytes32 encryptedTag;
    }
    /* We make sure the index tagIdxMap resolves to is the same for both
    tagList and keccakTagsList */
    struct TagData{
        mapping (bytes32 => uint) tagIdxMap;
        TagWrapStruct[] tagList;
        bytes32[] keccakTagsList;
        mapping (bytes32 => bool) tagExistMap;
    }
    struct AliasWrapStruct{
        TagData tagData;
        bytes32 encryptedAlias;
        uint aliasIdx;
        address aliasOwner;
    }
    mapping (bytes32 => uint) aliasIdxMap;
    mapping (bytes32 => bool) aliasExistMap;
    AliasWrapStruct[] aliasList;

    TNSOwnerReverse tnsOwnerReverse;

    bytes32 defaultAddress = 0xcfee7c08a98f4b565d124c7e4e28acc52e1bc780e3887db0a02a7d2d5bc66728;
    
    //modifiers
    modifier isOwner(bytes32 aliasName){
        require(aliasExistMap[aliasName] == true, "Alias doesn't exist");
        require(msg.sender == aliasList[aliasIdxMap[aliasName]].aliasOwner, "Only alias owner can call this function");
        _;
    }
    modifier aliasTagExist(bytes32 aliasName, bytes32 tagName){
        require(isAliasAvailable(aliasName) == false && isTagAvailable(aliasName,tagName) == false,
            "Alias or tag doesn't exist");
        _;
    }
    modifier aliasExist(bytes32 aliasName){
        require(isAliasAvailable(aliasName) == false, "Alias doesn't exist!");
        _;
    }
    modifier tagExist(bytes32 aliasName, bytes32 tagName){
        require(isTagAvailable(aliasName, tagName) == false, "Tag doesn't exist for alias!");
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

        aliasExistMap[aliasName] = true;
        uint alias_idx = aliasList.length;
        aliasIdxMap[aliasName] = alias_idx;
        aliasList.length++;
        AliasWrapStruct storage alias_wrap_data = aliasList[alias_idx];
        alias_wrap_data.encryptedAlias = encryptedAlias;
        alias_wrap_data.aliasIdx = alias_idx;
        alias_wrap_data.aliasOwner = msg.sender;
        

        TagData storage storage_tag_data = alias_wrap_data.tagData;
        storage_tag_data.tagExistMap[tagName] = true;
        uint tag_idx = storage_tag_data.tagList.length;
        storage_tag_data.tagList.length++;

        TagWrapStruct storage tag_wrapper = storage_tag_data.tagList[tag_idx];
        tag_wrapper.tnsTagData = tns_tag;
        tag_wrapper.encryptedTag = encryptedTag;
        storage_tag_data.tagIdxMap[tagName] = tag_idx;
        storage_tag_data.keccakTagsList.push(tagName);

        //reverse mapping
        tnsOwnerReverse.addOwnerAddress(msg.sender, aliasName);
    }

    function addNewTag(bytes32 aliasName, bytes32 tagName, bytes32 encryptedTag,
        TNSTag.TNSTagData tns_tag) private{

        uint alias_idx = aliasIdxMap[aliasName];
        TagData storage storage_tag_data = aliasList[alias_idx].tagData;
        storage_tag_data.tagExistMap[tagName] = true;
        TagWrapStruct memory tag_wrapper = TagWrapStruct({
            tnsTagData: tns_tag,
            encryptedTag: encryptedTag
        });
        storage_tag_data.tagIdxMap[tagName] = storage_tag_data.tagList.length;
        storage_tag_data.tagList.push(tag_wrapper);
        storage_tag_data.keccakTagsList.push(tagName);
    }

    //tagName would be address of "default" or actual tag name
    function setAliasStatic(bytes32 aliasName, bytes32 encryptedAlias, bytes32 tagName,
        bytes32 encryptedTag, address pubAddress) public aliasEmpty(aliasName) tagEmpty(tagName){

        require(pubAddress != 0x0, "pubAddress is empty");
        
        TNSTag.TNSTagData memory tns_tag;
        tns_tag.tagMetaDataStruct.pubAddress = pubAddress;


        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasList[aliasIdxMap[aliasName]].aliasOwner == msg.sender){
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
        tns_tag.genAddressStruct.generateAddress = true;
        tns_tag.genAddressStruct.genAddressList = genAddressList; 

        if (isAliasAvailable(aliasName)){
            addNewAlias(aliasName, encryptedAlias, tagName, encryptedTag, tns_tag);
        }else if (aliasList[aliasIdxMap[aliasName]].aliasOwner == msg.sender){
            require(isTagAvailable(aliasName, tagName), "Tag already exists");
            addNewTag(aliasName, tagName, encryptedTag, tns_tag);
        }else{
            revert("Alias is already taken");
        }
       emit StateAliasUpdated(msg.sender, aliasName);
    }

    //Entire alias & its corresponding tags cannot be deleted but can only be updated
    function deleteAliasTag(bytes32 aliasName, bytes32 tagName) public aliasEmpty(aliasName) tagEmpty(tagName)
        aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;

        delete storage_tag_data.tagExistMap[tagName];

        uint curr_tag_idx = storage_tag_data.tagIdxMap[tagName];
        uint tag_last_idx = storage_tag_data.tagList.length - 1;

        storage_tag_data.keccakTagsList[curr_tag_idx] = storage_tag_data.keccakTagsList[tag_last_idx];
        storage_tag_data.tagIdxMap[storage_tag_data.keccakTagsList[tag_last_idx]] = curr_tag_idx;
        storage_tag_data.keccakTagsList.length--;
       
        storage_tag_data.tagList[curr_tag_idx] = storage_tag_data.tagList[tag_last_idx];
        storage_tag_data.tagList.length--;

        delete storage_tag_data.tagIdxMap[tagName];

        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateAlias(bytes32 aliasName, bytes32 oldEncryptedAlias, bytes32 newAliasName,
        bytes32 newEncryptedAlias) public aliasEmpty(aliasName) isOwner(aliasName){

        require(newAliasName[0] != 0, "New Alias is empty");
        require(isAliasAvailable(newAliasName), "Alias is already taken");

        delete aliasExistMap[aliasName];
        aliasExistMap[newAliasName] = true;
        uint alias_idx = aliasIdxMap[aliasName];
        aliasIdxMap[newAliasName] = alias_idx;
        delete aliasIdxMap[aliasName];

        aliasList[alias_idx].encryptedAlias = newEncryptedAlias;

        tnsOwnerReverse.updateAlias(msg.sender, aliasName, newAliasName);

        emit StateUpdated(msg.sender);
    }

    function updateTag(bytes32 aliasName, bytes32 tagName, bytes32 oldEncryptedTag,
        bytes32 newTagName, bytes32 newEncryptedTag) public aliasEmpty(aliasName) tagEmpty(tagName) 
            aliasTagExist(aliasName, tagName) isOwner(aliasName){

        require(newTagName[0] != 0, "New tag is empty");
        require(isTagAvailable(aliasName, newTagName), "Tag already exists");

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        delete storage_tag_data.tagExistMap[tagName];
        storage_tag_data.tagExistMap[newTagName] = true;

        uint tag_idx = storage_tag_data.tagIdxMap[tagName];
        storage_tag_data.tagList[tag_idx].encryptedTag = newEncryptedTag;

        storage_tag_data.keccakTagsList[tag_idx] = newTagName;
        storage_tag_data.tagIdxMap[newTagName] = tag_idx;
        delete storage_tag_data.tagIdxMap[tagName];

        emit StateUpdated(msg.sender);
    }

    function updatePubAddressForTag(bytes32 aliasName, bytes32 tagName,
        address newPubAddress) public aliasEmpty(aliasName) tagEmpty(tagName)
        aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];

        if (newPubAddress == 0x0){
            if (storage_tag_data.tagList[tag_struct_idx].tnsTagData.getGenAddressFlag() == false){
                revert("In order to unset public address, auto-generated addresses option must be on and have rotating addresses. Only one option can be on at any given time.");
            }
        }
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.setPubAddress(newPubAddress);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressFlag(bytes32 aliasName, bytes32 tagName, bool genFlag) public aliasEmpty(aliasName) tagEmpty(tagName)
        aliasTagExist(aliasName, tagName) isOwner(aliasName){
        
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.setGenAddressFlag(genFlag);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListReplace(bytes32 aliasName, bytes32 tagName,
        address[] addressList) public aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.setGenAddressList(addressList);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListAppend(bytes32 aliasName, bytes32 tagName,
        address newAddress) public aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];

        uint num_elems =  storage_tag_data.tagList[tag_struct_idx].tnsTagData.getGenAddressListLen();
        require(num_elems < 20, "You can only store up to 20 addresses in order to obey gas limit.");
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.appendGenAddressList(newAddress);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateGenAddressListDelete(bytes32 aliasName, bytes32 tagName, uint idxToRemove) public
        aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];

        storage_tag_data.tagList[tag_struct_idx].tnsTagData.deleteFromGenAddressList(idxToRemove);
        emit StateAliasUpdated(msg.sender, aliasName);
    }

    function updateTagIsSecret(bytes32 aliasName, bytes32 tagName, bool isSecret)  aliasEmpty(aliasName) tagEmpty(tagName)
        aliasTagExist(aliasName, tagName) isOwner(aliasName) public{
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.setIsSecret(isSecret);
    }

    function updateTagSecretUserList(bytes32 aliasName, bytes32 tagName, bytes32[] keccakUsers,
        bytes32[] encUsers)  aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName) public{

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.setSecretUserList(keccakUsers,encUsers);
    }

    function updateTagSecretUserListAppend(bytes32 aliasName, bytes32 tagName, bytes32 keccakUser,
        bytes32[] encUser)  aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName) public{

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.appendSecretUser(keccakUser,encUser);
    }

    function updateTagSecretUserDelete(bytes32 aliasName, bytes32 tagName, bytes32 keccakUser,
        uint idxToRemove)  aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName) public{

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.deleteSecretUser(keccakUser,idxToRemove);
    }

    //GETTERS

    function getGenAddressList(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(address[]){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressList();
    }

    function getGenAddressListLen(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(uint){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressListLen();
    }

    function getPubAddressForTag(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(address){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getPubAddress();
    }

    function getGenAddressForTag(bytes32 aliasName, bytes32 tagName, uint idx) aliasTagExist(aliasName,tagName)
        public view returns(address){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.useNextGenAddress(idx);
    }

    function getGenAddressFlag(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(bool){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressFlag();
    }

    function isAliasAvailable(bytes32 aliasName) public view returns(bool){
        if (aliasExistMap[aliasName] == false){
            return true;
        }
        return false;
    }
    function isTagAvailable(bytes32 aliasName, bytes32 tagName) public view returns(bool){
        if (aliasExistMap[aliasName] == true){
            if (aliasList[aliasIdxMap[aliasName]].tagData.tagExistMap[tagName] == true){
                return false;
            }
        }
        return true;
    }
    function getAllTagsForAlias(bytes32 aliasName) aliasExist(aliasName) public view returns(bytes32[]){
        return aliasList[aliasIdxMap[aliasName]].tagData.keccakTagsList;
    }
    function getAliasesForOwner(address ownerAddress) public view returns(bytes32[]){
        return tnsOwnerReverse.getAllAliasesForOwner(ownerAddress);
    }
    function getEncryptedAliasForKeccak(bytes32 aliasName) aliasExist(aliasName) public view returns(bytes32){
        return aliasList[aliasIdxMap[aliasName]].encryptedAlias;
    }
    function getEncryptedTagForKeccak(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName, tagName)
        public view returns(bytes32){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].encryptedTag;
    }

    function getAliasOwner(bytes32 aliasName) aliasExist(aliasName) public view returns(address){
        return aliasList[aliasIdxMap[aliasName]].aliasOwner;
    }

    function getTagDataForTag(bytes32 aliasName, bytes32 tagName) public view
        returns(bool,bool,address[],bytes32[],address){

        address[] memory gen_list = getGenAddressList(aliasName, tagName);
        bytes32[] memory enc_secret_users = getSecretUserList(aliasName, tagName);
        address pub_address = getPubAddressForTag(aliasName, tagName);
        bool gen_flag = getGenAddressFlag(aliasName, tagName);
        bool is_tag_secret = getIsTagSecret(aliasName, tagName);
        return (gen_flag, is_tag_secret, gen_list, enc_secret_users, pub_address);
    }

    function isSecretUser(bytes32 aliasName, bytes32 tagName, bytes32 keccakUser) aliasTagExist(aliasName,tagName) public view returns(bool){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.secretUserExists(keccakUser);
    }

    function getSecretUserList(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(bytes32[]){ 
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getSecretUserList();
    }

    function getIsTagSecret(bytes32 aliasName, bytes32 tagName) aliasTagExist(aliasName,tagName)
        public view returns(bool){
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getIsSecret();
    }

}
