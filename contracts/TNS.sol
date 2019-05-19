pragma solidity ^0.4.23;

import {TNSOwnerReverse} from "./TNSOwnerReverse.sol";

contract TNS{
    using TagDataLib for TagDataLib.TagData;
    struct TagWrapStruct{
        TagDataLib.TagData tnsTagData;
        bytes32 encryptedTag;
    }
    /* We make sure the index tagIdxMap resolves to is the same for both
    tagList and keccakTagsList */
    struct BaseTagMetaData{
        mapping (bytes32 => uint) tagIdxMap;
        TagWrapStruct[] tagList;
        bytes32[] keccakTagsList;
        mapping (bytes32 => bool) tagExistMap; //get rid of it
    }
    struct AliasWrapStruct{
        BaseTagMetaData tagData;
        bytes32 encryptedAlias;
        uint aliasIdx; //get rid of it
        address aliasOwner;
    }
    mapping (bytes32 => uint) aliasIdxMap;
    mapping (bytes32 => bool) aliasExistMap; //get rid of it
    AliasWrapStruct[] aliasList;

    TNSOwnerReverse tnsOwnerReverse;

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
        require(alias != bytes32(0), "Alias is empty");
        _;
    }
    modifier tagEmpty(bytes32 tag){
        require(tag != bytes32(0), "Tag is empty");
        _;
    }
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
    }

    function updateAlias(bytes32 aliasName, bytes32 oldEncryptedAlias, bytes32 newAliasName,
        bytes32 newEncryptedAlias) public aliasEmpty(aliasName) isOwner(aliasName){

        require(newAliasName != bytes32(0), "New Alias is empty");
        require(isAliasAvailable(newAliasName), "Alias is already taken");

        delete aliasExistMap[aliasName];
        aliasExistMap[newAliasName] = true;
        uint alias_idx = aliasIdxMap[aliasName];
        aliasIdxMap[newAliasName] = alias_idx;
        delete aliasIdxMap[aliasName];

        aliasList[alias_idx].encryptedAlias = newEncryptedAlias;

        tnsOwnerReverse.updateAlias(msg.sender, aliasName, newAliasName);
    }

    function updateTag(bytes32 aliasName, bytes32 tagName, bytes32 oldEncryptedTag,
        bytes32 newTagName, bytes32 newEncryptedTag) public aliasEmpty(aliasName) tagEmpty(tagName) 
            aliasTagExist(aliasName, tagName) isOwner(aliasName){

        require(newTagName != bytes32(0), "New tag is empty");
        require(isTagAvailable(aliasName, newTagName), "Tag already exists");

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        delete storage_tag_data.tagExistMap[tagName];
        storage_tag_data.tagExistMap[newTagName] = true;

        uint tag_idx = storage_tag_data.tagIdxMap[tagName];
        storage_tag_data.tagList[tag_idx].encryptedTag = newEncryptedTag;

        storage_tag_data.keccakTagsList[tag_idx] = newTagName;
        storage_tag_data.tagIdxMap[newTagName] = tag_idx;
        delete storage_tag_data.tagIdxMap[tagName];
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
    }

    function updateGenAddressFlag(bytes32 aliasName, bytes32 tagName, bool genFlag) public aliasEmpty(aliasName) tagEmpty(tagName)
        aliasTagExist(aliasName, tagName) isOwner(aliasName){
        
        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.setGenAddressFlag(genFlag);
    }


    function updateGenAddressListAppend(bytes32 aliasName, bytes32 tagName,
        address newAddress) public aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];

        uint num_elems =  storage_tag_data.tagList[tag_struct_idx].tnsTagData.getGenAddressListLen();
        require(num_elems < 20, "You can only store up to 20 addresses in order to obey gas limit.");
        storage_tag_data.tagList[tag_struct_idx].tnsTagData.appendGenAddressList(newAddress);
    }

    function updateGenAddressListDelete(bytes32 aliasName, bytes32 tagName, uint idxToRemove) public
        aliasEmpty(aliasName) tagEmpty(tagName) aliasTagExist(aliasName, tagName) isOwner(aliasName){

        TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
        uint tag_struct_idx = storage_tag_data.tagIdxMap[tagName];

        storage_tag_data.tagList[tag_struct_idx].tnsTagData.deleteFromGenAddressList(idxToRemove);
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

    //work around instead of using modifiers since there's a bug in tronWeb that disallows require calls in view functions
    function doesAliasTagExist(bytes32 aliasName, bytes32 tagName) private view returns(bool){
        return isAliasAvailable(aliasName) == false && isTagAvailable(aliasName,tagName) == false;
    }

    function doesAliasExist(bytes32 aliasName) private view returns(bool){
        return isAliasAvailable(aliasName) == false;
    }

    //GETTERS

    function getGenAddressList(bytes32 aliasName, bytes32 tagName)
        public view returns(address[]){

        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressList();
        }else{
            address[] memory empty_array = new address[](0);
            return empty_array;
        }
    }

    function getGenAddressListLen(bytes32 aliasName, bytes32 tagName)
        public view returns(uint){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressListLen();
        }else{
            return 0;
        }
    }

    function getPubAddressForTag(bytes32 aliasName, bytes32 tagName)
        public view returns(address){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getPubAddress();
        }else{
            return address(0);
        }
    }

    function getGenAddressForTag(bytes32 aliasName, bytes32 tagName, uint idx)
        public view returns(address){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.useNextGenAddress(idx);
        }else{
            return address(0);
        }
    }

    function getGenAddressFlag(bytes32 aliasName, bytes32 tagName)
        public view returns(bool){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getGenAddressFlag();
        }else {
            return false;
        }
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
    function getAllTagsForAlias(bytes32 aliasName) public view returns(bytes32[]){
        if (doesAliasExist(aliasName)){
            return aliasList[aliasIdxMap[aliasName]].tagData.keccakTagsList;
        }else{
            bytes32[] memory empty_array = new bytes32[](0);
            return empty_array;
        }
    }
    function getAliasesForOwner(address ownerAddress) public view returns(bytes32[]){
        return tnsOwnerReverse.getAllAliasesForOwner(ownerAddress);
    }
    function getEncryptedAliasForKeccak(bytes32 aliasName) public view returns(bytes32){
        if (doesAliasExist(aliasName)){
            return aliasList[aliasIdxMap[aliasName]].encryptedAlias;
        }else{
            return 0x0;
        }
    }
    function getEncryptedTagForKeccak(bytes32 aliasName, bytes32 tagName) 
        public view returns(bytes32){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].encryptedTag;
        }else{
            return 0x0;
        }
    }

    function getAliasOwner(bytes32 aliasName) public view returns(address){
        if (doesAliasExist(aliasName)){
            return aliasList[aliasIdxMap[aliasName]].aliasOwner;
        }else{
            return address(0);
        }
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

    function isSecretUser(bytes32 aliasName, bytes32 tagName, bytes32 keccakUser) public view returns(bool){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.secretUserExists(keccakUser);
        }else{
            return false;
        }
    }

    function getSecretUserList(bytes32 aliasName, bytes32 tagName) 
        public view returns(bytes32[]){ 
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getSecretUserList();
        }else{
            bytes32[] memory empty_array = new bytes32[](0);
            return empty_array;
        }
    }

    function getIsTagSecret(bytes32 aliasName, bytes32 tagName)
        public view returns(bool){
        if (doesAliasTagExist(aliasName,tagName)){
            TagData storage storage_tag_data = aliasList[aliasIdxMap[aliasName]].tagData;
            return storage_tag_data.tagList[storage_tag_data.tagIdxMap[tagName]].tnsTagData.getIsSecret();
        }else{
            return false;
        }
    }

}
