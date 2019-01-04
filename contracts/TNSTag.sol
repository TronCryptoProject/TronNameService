pragma solidity ^0.4.23;

library TNSTag{
    struct GenAddress{
        address[] genAddressList;
        bool generateAddress;
    }

    struct TagMetaData{
        address pubAddress;
        bool isSecret;
        mapping(bytes32=>uint) secretUsersIdxMap; //keccak => SecretUser[] idx + 1 <- will be 0 for non-exist key
        bytes32[] secretUsers;
        bytes32[] encUsers; //can only be decrypted by alias owner
    }

    struct TNSTagData{
        GenAddress genAddressStruct;
        TagMetaData tagMetaDataStruct;
    }


    function setPubAddress(TNSTagData storage data, address pubAddress) public{
        data.tagMetaDataStruct.pubAddress = pubAddress;
    }

    function getPubAddress(TNSTagData storage data) public view returns(address){
        return data.tagMetaDataStruct.pubAddress;
    }

    function setGenAddressFlag(TNSTagData storage data, bool genFlag) public{
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

    function getGenAddressFlag(TNSTagData storage data) public view returns(bool){
        return data.genAddressStruct.generateAddress;
    }


    function appendGenAddressList(TNSTagData storage data, address genAddress) public{
        require(data.genAddressStruct.genAddressList.length < 20, "Cannot add more than 20 auto-gen addresses");
        data.genAddressStruct.genAddressList.push(genAddress);
    }

    function setGenAddressList(TNSTagData storage data, address[] genAddressList) public{
        require(genAddressList.length <= 20, "Cannot add more than 20 auto-gen addresses");
        data.genAddressStruct.genAddressList = genAddressList;
        data.genAddressStruct.genAddressList.length = genAddressList.length;
        if (genAddressList.length == 0){
            data.genAddressStruct.generateAddress = false;
        }else{
            data.genAddressStruct.generateAddress = true;
        }
    }

    function deleteFromGenAddressList(TNSTagData storage data, uint idxToRemove) public{
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

    function getGenAddressList(TNSTagData storage data) public view returns(address[]){
        return data.genAddressStruct.genAddressList;
    }

    function getGenAddressListLen(TNSTagData storage data) public view returns(uint){
        return data.genAddressStruct.genAddressList.length;
    }

    //random number generation off-chain
    function useNextGenAddress(TNSTagData storage data, uint listIdx) public view returns(address){
        return data.genAddressStruct.genAddressList[listIdx];
    }


    function setIsSecret(TNSTagData storage data, bool isSecret) public{
        data.tagMetaDataStruct.isSecret = isSecret;
    }
    
    function getIsSecret(TNSTagData storage data) public view returns(bool){
        return data.tagMetaDataStruct.isSecret;
    }

    function setSecretUserList(TNSTagData storage data, bytes32[] keccakUsers, bytes32[] encUsers) public{
        require((encUsers.length/2) <= 10, "Cannot set more than 10 secret users");
        uint secret_users_len = data.tagMetaDataStruct.secretUsers.length;
        uint max_len = secret_users_len > keccakUsers.length ? secret_users_len: keccakUsers.length;

        //optimization
        for(uint i = 0; i < (max_len == secret_users_len ? keccakUsers.length:secret_users_len); i++){
            delete data.tagMetaDataStruct.secretUsersIdxMap[data.tagMetaDataStruct.secretUsers[i]];
            data.tagMetaDataStruct.secretUsers[i] = keccakUsers[i];
            data.tagMetaDataStruct.secretUsersIdxMap[keccakUsers[i]] = i + 1;
        }

        if (max_len == secret_users_len){
            for(uint r = keccakUsers.length; r < max_len; r++){  //zero out
                delete data.tagMetaDataStruct.secretUsersIdxMap[data.tagMetaDataStruct.secretUsers[r]];
                delete data.tagMetaDataStruct.secretUsers[r];
            }
        }else{
            for(uint new_idx = secret_users_len; new_idx < max_len; new_idx++){
                data.tagMetaDataStruct.secretUsersIdxMap[keccakUsers[new_idx]] = r + 1;
                uint last_idx = data.tagMetaDataStruct.secretUsers.length;
                data.tagMetaDataStruct.secretUsers.length++;
                data.tagMetaDataStruct.secretUsers[last_idx] = keccakUsers[new_idx];
            }
        }
		data.tagMetaDataStruct.encUsers = encUsers;
    }
  
    function getSecretUserList(TNSTagData storage data) public view returns(bytes32[]){
		return data.tagMetaDataStruct.encUsers;
    }

    function appendSecretUser(TNSTagData storage data, bytes32 newKeccakUser, bytes32[] newEncUser) public{
        require((data.tagMetaDataStruct.encUsers.length/2) < 10, "Cannot set more than 10 secret users");
        require(newEncUser.length == 2, "EncUser array length is not 2");
		data.tagMetaDataStruct.encUsers.push(newEncUser[0]);
        data.tagMetaDataStruct.encUsers.push(newEncUser[1]);

        data.tagMetaDataStruct.secretUsersIdxMap[newKeccakUser] = data.tagMetaDataStruct.secretUsers.length + 1;
        uint last_idx = data.tagMetaDataStruct.secretUsers.length;
        data.tagMetaDataStruct.secretUsers.length++;
        data.tagMetaDataStruct.secretUsers[last_idx] = newKeccakUser;
    }

    function deleteSecretUser(TNSTagData storage data, bytes32 keccakUser, uint idxToRemove) public{
        uint curr_len = data.tagMetaDataStruct.encUsers.length;
        uint parsed_idx = idxToRemove * 2;
        require(idxToRemove >= 0 && idxToRemove < (curr_len/2), "Index ix out of bounds");
        require(curr_len >= 2, "Array is empty, nothing to delete");
        require(data.tagMetaDataStruct.secretUsersIdxMap[keccakUser] != 0, "Secret User doesn't exist");

        data.tagMetaDataStruct.encUsers[parsed_idx + 1] = data.tagMetaDataStruct.encUsers[curr_len - 1];
        data.tagMetaDataStruct.encUsers[parsed_idx] = data.tagMetaDataStruct.encUsers[curr_len - 2];
        data.tagMetaDataStruct.encUsers.length--;
        data.tagMetaDataStruct.encUsers.length--;

        uint secret_user_idx = data.tagMetaDataStruct.secretUsersIdxMap[keccakUser] - 1;
        data.tagMetaDataStruct.secretUsers[secret_user_idx] = data.tagMetaDataStruct.secretUsers[data.tagMetaDataStruct.secretUsers.length - 1];
        data.tagMetaDataStruct.secretUsersIdxMap[data.tagMetaDataStruct.secretUsers[secret_user_idx]] = secret_user_idx + 1;
        data.tagMetaDataStruct.secretUsers.length--;
        delete data.tagMetaDataStruct.secretUsersIdxMap[keccakUser];
    }

    function secretUserExists(TNSTagData storage data, bytes32 keccakUser) public view returns(bool){
        return data.tagMetaDataStruct.secretUsersIdxMap[keccakUser] == 0 ? false:true;
    }
}
