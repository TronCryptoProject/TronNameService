pragma solidity ^0.4.23;

library TNSTag{
    struct GenAddress{
        bytes32[] genAddressList;
        uint numElements;
        bool generateAddress;
    }
    struct TagMetaData{
        bytes32 pubAddress;
        /* TODO:
        bool isSecret, 
        bytes32[] secretApprovedMembers*/
    }
    
    struct TNSTagData{
        GenAddress genAddressStruct;
        TagMetaData tagMetaDataStruct;
        bool isExist;
    }
    

    function setExist(TNSTagData storage data, bool isExist) public{
        data.isExist = isExist;
    }

    function getExist(TNSTagData storage data) public view returns(bool){
        return data.isExist;
    }

    function setPubAddress(TNSTagData storage data, bytes32 pubAddress) public{
        data.tagMetaDataStruct.pubAddress = pubAddress;
    } 

    function getPubAddress(TNSTagData storage data) public view returns(bytes32){
        return data.tagMetaDataStruct.pubAddress;
    }

    function setGenAddressFlag(TNSTagData storage data, bool genFlag) public{
        data.genAddressStruct.generateAddress = genFlag;
    }

    function getGenAddressFlag(TNSTagData storage data) public view returns(bool){
        return data.genAddressStruct.generateAddress;
    }


    function appendGenAddressList(TNSTagData storage data, bytes32 genAddress) public{
        data.genAddressStruct.numElements++;
        data.genAddressStruct.genAddressList.push(genAddress);
    }

    //set list is always called before append
    function setGenAddressList(TNSTagData storage data, bytes32[] genAddressList) public{
        data.genAddressStruct.generateAddress = true;
        data.genAddressStruct.genAddressList = genAddressList; 
        data.genAddressStruct.numElements = genAddressList.length;
    }

    /*genAddressFlag will still be set if addressList becomes empty. In that case, it won't default to 
    pubAddress if it's set*/
    function deleteFromGenAddressList(TNSTagData storage data, uint idxToRemove) public{
        require(idxToRemove >= 0 && idxToRemove < data.genAddressStruct.numElements,"Index ix out of bounds");
        require(data.genAddressStruct.numElements > 0, "Array is empty, nothing to delete");

        if (data.genAddressStruct.numElements > 1){
            data.genAddressStruct.genAddressList[idxToRemove] = data.genAddressStruct.genAddressList[--data.genAddressStruct.numElements];
            delete data.genAddressStruct.genAddressList[data.genAddressStruct.numElements];
        }else{
            delete data.genAddressStruct.genAddressList[idxToRemove];
        }
    }
 
    function getGenAddressList(TNSTagData storage data) public view returns(bytes32[]){
        return data.genAddressStruct.genAddressList;
    }

    //random number generation off-chain
    function useNextGenAddress(TNSTagData storage data, uint listIdx) public view returns(bytes32){
        return data.genAddressStruct.genAddressList[listIdx];
    }
}