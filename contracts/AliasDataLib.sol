pragma solidity ^0.4.23;

library AliasDataLib{
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
        mapping (bytes32 => bool) tagExistMap;
    }
    struct AliasWrapStruct{
        BaseTagMetaData tagData;
        bytes32 encryptedAlias;
        uint aliasIdx;
        address aliasOwner;
    }


}