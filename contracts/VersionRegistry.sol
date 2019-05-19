pragma solidity ^0.4.23;

import "./BaseConfig.sol";

contract VersionRegistry is BaseConfig{

    modifier libraryExistence(bytes32 name, uint version, bool libMustNonExist){
        if (libMustNonExist){
            require(registry[name].versions[version] == address(0), "Library already exists");
        }else{
            require(registry[name].versions[version] != address(0), "Library doesn't exist");
        }
        _;
    }

    /*library address may be updated to recent one but we may need to use old addresses for legacy support 
    as long as the fix is not dire */
    struct LibMetaData{
        uint currVersion;
        mapping(uint=>address) versions;
    }
    //bytes32 => keccak of library name
    mapping (bytes32=>LibMetaData) internal registry;



    //must call setVersionActive() after this function in order to make input library address active
    function addLibrary(bytes32 name, uint version, address libAddress) isMainOwner notEmptyBytes32(name)
        notEmptyAddr(libAddress) libraryExistence(name, version, true) public{
        registry[name].versions[version] = libAddress;
    }

    //we provide this function so that someone doesn't accidentally override lib address for a version
    function updateLibrary(bytes32 name, uint version, address libAddress) isMainOwner notEmptyBytes32(name) 
        notEmptyAddr(libAddress) libraryExistence(name, version, false) public{
        registry[name].versions[version] = libAddress;
    }

    function setVersionActive(bytes32 name, uint version) isMainOwner notEmptyBytes32(name) 
        libraryExistence(name, version, false) public{
        registry[name].currVersion = version;
    }

    function getLibAddress(bytes32 name, uint version) notEmptyBytes32(name) 
        libraryExistence(name, version, false) public view returns(address){
        return registry[name].versions[version];
    }

    function getCurrVersion(bytes32 name) notEmptyBytes32(name) public view returns(address){
        return getLibAddress(name, registry[name].currVersion);
    }
}