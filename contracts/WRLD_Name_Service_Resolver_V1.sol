// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Bridge.sol";
import "./IWRLD_Name_Service_Storage.sol";

// Resolvers can be updated without needing to migrate storage
// Multiple resolvers can be deployed for each storage
contract WRLD_NameService_Resolver_V1 is IWRLD_Name_Service_Resolver {
  IWRLD_Name_Service_Bridge nameServiceBridge;
  IWRLD_Name_Service_Storage nameServiceStorage;


  constructor(address _nameServiceBridge, address _nameServiceStorage) {
    nameServiceBridge = IWRLD_Name_Service_Bridge(_nameServiceBridge);
    nameServiceStorage = IWRLD_Name_Service_Storage(_nameServiceStorage);
  }

  /******************
   * Record Setters *
   ******************/
   // To delete records simply set them to empty
   // Enumeration needs to be implemented off-chain since there's no efficient CRUD implementation for string type

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setStringRecord(tokenId, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setAddressRecord(tokenId, _record, _value, _ttl);
  }

  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setUintRecord(tokenId, _record, _value, _ttl);
  }

  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external override onlyAuthd(tokenId) {
    nameServiceStorage.setIntRecord(tokenId, _record, _value, _ttl);
  }

  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external override onlyAuthd(tokenId) {
    nameServiceStorage.setWalletRecord(tokenId, _record, _value);
  }

  /******************
   * Record Getters *
   ******************/

  function getStringRecord(uint256 tokenId, string calldata _record) external view override returns (StringRecord memory) {
    return nameServiceStorage.getStringRecord(tokenId, _record);
  }

  function getAddressRecord(uint256 tokenId, string calldata _record) external view override returns (AddressRecord memory) {
    return nameServiceStorage.getAddressRecord(tokenId, _record);
  }

  function getUintRecord(uint256 tokenId, string calldata _record) external view override returns (UintRecord memory) {
    return nameServiceStorage.getUintRecord(tokenId, _record);
  }

  function getIntRecord(uint256 tokenId, string calldata _record) external view override returns (IntRecord memory) {
    return nameServiceStorage.getIntRecord(tokenId, _record);
  }

  function getWalletRecord(uint256 tokenId, uint256 _record) external view override returns (string memory) {
    return nameServiceStorage.getWalletRecord(tokenId, _record);
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Resolver).interfaceId;
  }

  /*************
   * Modifiers *
   *************/

  modifier onlyAuthd(uint256 tokenId) {
    require(nameServiceBridge.isAuthd(tokenId, msg.sender), "Sender is not authorized.");
    _;
  }
}
