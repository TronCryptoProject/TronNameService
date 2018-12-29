pragma solidity ^0.4.23;

library TNSTag{
  struct GenAddress{
	address[] genAddressList;
	uint numElements;
	bool generateAddress;
  }
  struct TagMetaData{
	address pubAddress;
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
  
  function setPubAddress(TNSTagData storage data, address pubAddress) public{
		data.tagMetaDataStruct.pubAddress = pubAddress;
  }
  
  function getPubAddress(TNSTagData storage data) public view returns(address){
		return data.tagMetaDataStruct.pubAddress;
  }
  
  function setGenAddressFlag(TNSTagData storage data, bool genFlag) public{
	  	if(genFlag){
			if (data.genAddressStruct.numElements == 0){
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
		data.genAddressStruct.numElements++;
		data.genAddressStruct.genAddressList.push(genAddress);
		if (data.genAddressStruct.generateAddress == false){
			data.genAddressStruct.generateAddress = true;
		}
  }
  
  function setGenAddressList(TNSTagData storage data, address[] genAddressList) public{
		data.genAddressStruct.genAddressList = genAddressList;
		data.genAddressStruct.numElements = genAddressList.length;
		if (genAddressList.length == 0){
			data.genAddressStruct.generateAddress = false;
		}else{
			data.genAddressStruct.generateAddress = true;
		}
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
			if (data.tagMetaDataStruct.pubAddress == 0x0){
				revert("You are deleting the last auto-generated address, however, static address is not set. Please set static address before deleting this last address, so your alias/tag will automatically resolve to it!");
			}
			delete data.genAddressStruct.genAddressList[idxToRemove];
			data.genAddressStruct.generateAddress = false;
		}
  }
  
  function getGenAddressList(TNSTagData storage data) public view returns(address[]){
		return data.genAddressStruct.genAddressList;
  }
  
  function getGenAddressListLen(TNSTagData storage data) public view returns(uint){
		return data.genAddressStruct.numElements;
  }

  //random number generation off-chain
  function useNextGenAddress(TNSTagData storage data, uint listIdx) public view returns(address){
		return data.genAddressStruct.genAddressList[listIdx];
  }
}
  