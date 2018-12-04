pragma solidity ^0.4.23;

contract TNSTag{
    struct GenAddress{
        address[] genAddressList,
        uint numElements,
        bool generateAddress
    }
    struct TagMetaData{
        address pubAddress
        /* TODO:
        bool isSecret, 
        address[] secretApprovedMembers*/
    }
    GenAddress public genAddressStruct;
    TagMetaData public tagMetaDataStruct;

    function setPubAddress(address pubAddress) external{
        tagMetaDataStruct.pubAddress = pubAddress;
    } 

    function getPubAddress(address pubAddress) external view returns(address){
        return tagMetaDataStruct.pubAddress;
    }

    function setGenAddressFlag(bool genFlag) external{
        genAddressStruct.generateAddress = genFlag;
    }

    function getGenAddressFlag(bool genFlag) external view returns(bool){
        return genAddressStruct.generateAddress;
    }


    function appendGenAddressList(address genAddress) external{
        genAddressStruct.genAddressList[genAddressStruct.numElements++].push(genAddress);
    }

    //set list is always called before append
    function setGenAddressList(address[] genAddressList) external{
        genAddressStruct.generateAddress = true;
        genAddressStruct.genAddressList = genAddressList; 
        genAddressStruct.numElements = genAddressList.length;
    }

    /*genAddressFlag will still be set if addressList becomes empty. In that case, it won't default to 
    pubAddress if it's set*/
    function deleteFromGenAddressList(uint idxToRemove) external{
        require(idxToRemove >= 0 && idxToRemove < genAddressStruct.numElements,
            "Index ix out of bounds");
        require(genAddressStruct.numElements > 0, "Array is empty, nothing to delete");

        if (genAddressStruct.numElements > 1){
            genAddressStruct.genAddressList[idxToRemove] = genAddressStruct.genAddressList[--genAddressStruct.numElements];
            delete genAddressStruct.genAddressList[genAddressStruct.numElements];
        }else{
            delete genAddressStruct.genAddressList[idxToRemove];
        }
    }
 
    function getGenAddressList() external view returns(address[]){
        return genAddressStruct.genAddressList;
    }

    //random number generation off-chain
    function useNextGenAddress(listIdx) external view returns(address){
        return genAddressStruct.genAddressList[listIdx];
    }
}