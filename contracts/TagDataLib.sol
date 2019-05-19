pragma solidity ^0.4.23;

library TagDataLib{
    struct GenAddress{
        bool generateAddress;
        address[] genAddressList;
    }

    struct TagMetaData{
        address pubAddress;
    }

    struct SecretUsers{
        bool isSecret;
        mapping(bytes32=>uint) secretUsersIdxMap; //keccak => SecretUser[] idx + 1 <- will be 0 for non-exist key
        bytes32[] secretUsers;
        bytes32[] encUsers; //can only be decrypted by alias owner
    }

    struct TagData{
        GenAddress genAddressStruct;
        TagMetaData tagMetaDataStruct;
        SecretUsers secretUsersStruct;
    }


    function setPubAddress(TagData storage data, address pubAddress) public{
        data.tagMetaDataStruct.pubAddress = pubAddress;
    }

    function getPubAddress(TagData storage data) public view returns(address){
        return data.tagMetaDataStruct.pubAddress;
    }

    function setGenAddressFlag(TagData storage data, bool genFlag) public{
            if(genFlag){
            if (data.genAddressStruct.genAddressList.length == 0){
                revert("You cannot set auto-generate addresses since there are not addreses to be found. Please set some addresses first.");
            }
        }else{
            if (data.tagMetaDataStruct.pubAddress == 0x0){
                revert("Turning off auto-generated addresses will automatically make the alias/tag resolve to static addresss. However, static address is not set. Please set it before continuing.");
            }
        }
        data.genAddressStruct.generateAddress = genFlag;
    }

    function getGenAddressFlag(TagData storage data) public view returns(bool){
        return data.genAddressStruct.generateAddress;
    }


    function appendGenAddressList(TagData storage data, address genAddress) public{
        require(data.genAddressStruct.genAddressList.length < 20, "Cannot add more than 20 auto-gen addresses");
        data.genAddressStruct.genAddressList.push(genAddress);
    }

    function setGenAddressList(TagData storage data, address[] genAddressList) public{
        require(genAddressList.length <= 20, "Cannot add more than 20 auto-gen addresses");
        data.genAddressStruct.genAddressList = genAddressList;
        data.genAddressStruct.genAddressList.length = genAddressList.length;
        if (genAddressList.length == 0){
            data.genAddressStruct.generateAddress = false;
        }else{
            data.genAddressStruct.generateAddress = true;
        }
    }

    function deleteFromGenAddressList(TagData storage data, uint idxToRemove) public{
        uint curr_len = data.genAddressStruct.genAddressList.length;

        require(idxToRemove >= 0 && idxToRemove < curr_len,"Index ix out of bounds");
        require(curr_len > 0, "Array is empty, nothing to delete");
        
        if (curr_len > 1){
            data.genAddressStruct.genAddressList[idxToRemove] = data.genAddressStruct.genAddressList[curr_len - 1];
            data.genAddressStruct.genAddressList.length--;
        }else{
            if (data.tagMetaDataStruct.pubAddress == 0x0){
                revert("You are deleting the last auto-generated address, however, static address is not set. Please set static address before deleting this last auto-gen address, so your alias/tag will automatically resolve to it. Only either static address or auto-gen option can be on at any given time.");
            }
            data.genAddressStruct.genAddressList.length--;
            data.genAddressStruct.generateAddress = false;
        }
    }

    function getGenAddressList(TagData storage data) public view returns(address[]){
        return data.genAddressStruct.genAddressList;
    }

    function getGenAddressListLen(TagData storage data) public view returns(uint){
        return data.genAddressStruct.genAddressList.length;
    }

    //random number generation off-chain
    function useNextGenAddress(TagData storage data, uint listIdx) public view returns(address){
        return data.genAddressStruct.genAddressList[listIdx];
    }


    function setIsSecret(TagData storage data, bool isSecret) public{
        data.secretUsersStruct.isSecret = isSecret;
    }
    
    function getIsSecret(TagData storage data) public view returns(bool){
        return data.secretUsersStruct.isSecret;
    }

    function setSecretUserList(TagData storage data, bytes32[] keccakUsers, bytes32[] encUsers) public{
        require((encUsers.length/2) <= 10, "Cannot set more than 10 secret users");
        uint secret_users_len = data.secretUsersStruct.secretUsers.length;
        uint max_len = secret_users_len > keccakUsers.length ? secret_users_len: keccakUsers.length;

        //optimization
        for(uint i = 0; i < (max_len == secret_users_len ? keccakUsers.length:secret_users_len); i++){
            delete data.secretUsersStruct.secretUsersIdxMap[data.secretUsersStruct.secretUsers[i]];
            data.secretUsersStruct.secretUsers[i] = keccakUsers[i];
            data.secretUsersStruct.secretUsersIdxMap[keccakUsers[i]] = i + 1;
        }

        if (max_len == secret_users_len){
            for(uint r = keccakUsers.length; r < max_len; r++){  //zero out
                delete data.secretUsersStruct.secretUsersIdxMap[data.secretUsersStruct.secretUsers[r]];
                delete data.secretUsersStruct.secretUsers[r];
            }
        }else{
            for(uint new_idx = secret_users_len; new_idx < max_len; new_idx++){
                data.secretUsersStruct.secretUsersIdxMap[keccakUsers[new_idx]] = r + 1;
                uint last_idx = data.secretUsersStruct.secretUsers.length;
                data.secretUsersStruct.secretUsers.length++;
                data.secretUsersStruct.secretUsers[last_idx] = keccakUsers[new_idx];
            }
        }
		data.secretUsersStruct.encUsers = encUsers;
    }
  
    function getSecretUserList(TagData storage data) public view returns(bytes32[]){
		return data.secretUsersStruct.encUsers;
    }

    function appendSecretUser(TagData storage data, bytes32 newKeccakUser, bytes32[] newEncUser) public{
        require((data.secretUsersStruct.encUsers.length/2) < 10, "Cannot set more than 10 secret users");
        require(newEncUser.length == 2, "EncUser array length is not 2");
		data.secretUsersStruct.encUsers.push(newEncUser[0]);
        data.secretUsersStruct.encUsers.push(newEncUser[1]);

        data.secretUsersStruct.secretUsersIdxMap[newKeccakUser] = data.secretUsersStruct.secretUsers.length + 1;
        uint last_idx = data.secretUsersStruct.secretUsers.length;
        data.secretUsersStruct.secretUsers.length++;
        data.secretUsersStruct.secretUsers[last_idx] = newKeccakUser;
    }

    function deleteSecretUser(TagData storage data, bytes32 keccakUser, uint idxToRemove) public{
        uint curr_len = data.secretUsersStruct.encUsers.length;
        uint parsed_idx = idxToRemove * 2;
        require(idxToRemove >= 0 && idxToRemove < (curr_len/2), "Index ix out of bounds");
        require(curr_len >= 2, "Array is empty, nothing to delete");
        require(data.secretUsersStruct.secretUsersIdxMap[keccakUser] != 0, "Secret User doesn't exist");

        data.secretUsersStruct.encUsers[parsed_idx + 1] = data.secretUsersStruct.encUsers[curr_len - 1];
        data.secretUsersStruct.encUsers[parsed_idx] = data.secretUsersStruct.encUsers[curr_len - 2];
        data.secretUsersStruct.encUsers.length--;
        data.secretUsersStruct.encUsers.length--;

        uint secret_user_idx = data.secretUsersStruct.secretUsersIdxMap[keccakUser] - 1;
        data.secretUsersStruct.secretUsers[secret_user_idx] = data.secretUsersStruct.secretUsers[data.secretUsersStruct.secretUsers.length - 1];
        data.secretUsersStruct.secretUsersIdxMap[data.secretUsersStruct.secretUsers[secret_user_idx]] = secret_user_idx + 1;
        data.secretUsersStruct.secretUsers.length--;
        delete data.secretUsersStruct.secretUsersIdxMap[keccakUser];
    }

    function secretUserExists(TagData storage data, bytes32 keccakUser) public view returns(bool){
        return data.secretUsersStruct.secretUsersIdxMap[keccakUser] == 0 ? false:true;
    }
}
