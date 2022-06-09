// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

// Custom storage/resolver contracts can be deployed by anyone
contract WRLD_NameService_Storage is AccessControl, IWRLD_Name_Service_Storage {
  bytes32 public constant WRITE_ROLE = keccak256("WRITE_ROLE");

  mapping(uint256 => mapping(string => StringRecord)) private wrldStringRecords;
  mapping(uint256 => mapping(string => AddressRecord)) private wrldAddressRecords;
  mapping(uint256 => mapping(string => UintRecord)) private wrldUintRecords;
  mapping(uint256 => mapping(string => IntRecord)) private wrldIntRecords;
  mapping(uint256 => mapping(uint256 => string)) private wrldWalletRecords;  // SLIP-0044 coin type => address string https://github.com/satoshilabs/slips/blob/master/slip-0044.md


  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /******************
   * Record Setters *
   ******************/
   // To delete records simply set them to empty
   // Enumeration needs to be implemented off-chain since there's no efficient CRUD implementation for string type

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external override onlyRole(WRITE_ROLE) {
    wrldStringRecords[tokenId][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    emit StringRecordUpdated(tokenId, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external override onlyRole(WRITE_ROLE) {
    wrldAddressRecords[tokenId][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    emit AddressRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external override onlyRole(WRITE_ROLE) {
    wrldUintRecords[tokenId][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    emit UintRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external override onlyRole(WRITE_ROLE) {
   wrldIntRecords[tokenId][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    emit IntRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external override onlyRole(WRITE_ROLE) {
    wrldWalletRecords[tokenId][_record] = _value;

    emit WalletRecordUpdated(tokenId, _record, _value);
  }

  /******************
   * Record Getters *
   ******************/

  function getStringRecord(uint256 tokenId, string calldata _record) external view override returns (StringRecord memory) {
    return wrldStringRecords[tokenId][_record];
  }

  function getAddressRecord(uint256 tokenId, string calldata _record) external view override returns (AddressRecord memory) {
    return wrldAddressRecords[tokenId][_record];
  }

  function getUintRecord(uint256 tokenId, string calldata _record) external view override returns (UintRecord memory) {
    return wrldUintRecords[tokenId][_record];
  }

  function getIntRecord(uint256 tokenId, string calldata _record) external view override returns (IntRecord memory) {
    return wrldIntRecords[tokenId][_record];
  }

  function getWalletRecord(uint256 tokenId, uint256 _record) external view override returns (string memory) {
    return wrldWalletRecords[tokenId][_record];
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) public view override(AccessControl, IERC165) returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Storage).interfaceId;
  }

}