pragma solidity ^0.4.23;

library TNSTag{
  struct GenAddress{
	address[] genAddressList;
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
		data.genAddressStruct.genAddressList.push(genAddress);
		if (data.genAddressStruct.generateAddress == false){
			data.genAddressStruct.generateAddress = true;
		}
  }
  
  function setGenAddressList(TNSTagData storage data, address[] genAddressList) public{
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
}
  