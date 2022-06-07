// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Storage.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract WRLD_NameService_Storage is AccessControl, IWRLD_Name_Service_Storage {
  bytes32 public constant WRITE_ROLE = keccak256("WRITE_ROLE");

  mapping(uint256 => mapping(string => StringRecord)) private wrldStringRecords;
  mapping(uint256 => string[]) public wrldStringRecordsList;

  mapping(uint256 => mapping(string => AddressRecord)) private wrldAddressRecords;
  mapping(uint256 => string[]) public wrldAddressRecordsList;

  mapping(uint256 => mapping(string => UintRecord)) private wrldUintRecords;
  mapping(uint256 => string[]) public wrldUintRecordsList;

  mapping(uint256 => mapping(string => IntRecord)) private wrldIntRecords;
  mapping(uint256 => string[]) public wrldIntRecordsList;

  mapping(uint256 => mapping(uint256 => string)) private wrldWalletRecords;  // SLIP-0044 coin type => address string https://github.com/satoshilabs/slips/blob/master/slip-0044.md
  mapping(uint256 => uint256[]) public wrldWalletRecordsList;

  constructor() {
    _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
  }

  /******************
   * Record Setters *
   ******************/

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external override onlyRole("WRITE_ROLE") {
    wrldStringRecords[tokenId][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    wrldStringRecordsList[tokenId].push(_record);

    emit StringRecordUpdated(tokenId, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(uint256 tokenId, string memory _record, address _value, uint256 _ttl) external override onlyRole("WRITE_ROLE") {
    wrldAddressRecords[tokenId][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldAddressRecordsList[tokenId].push(_record);

    emit AddressRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint256 _ttl) external override onlyRole("WRITE_ROLE") {
    wrldUintRecords[tokenId][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldUintRecordsList[tokenId].push(_record);

    emit UintRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint256 _ttl) external override onlyRole("WRITE_ROLE") {
   wrldIntRecords[tokenId][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldIntRecordsList[tokenId].push(_record);

    emit IntRecordUpdated(tokenId, _record, _value, _ttl);
  }

  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external override onlyRole("WRITE_ROLE") {
    wrldWalletRecords[tokenId][_record] = _value;

    wrldWalletRecordsList[tokenId].push(_record);

    emit WalletRecordUpdated(tokenId, _record, _value, _ttl);
  }

  /******************
   * Record Getters *
   ******************/

  function getNameStringRecord(uint256 tokenId, string calldata _record) external view override returns (StringRecord memory) {
    return wrldStringRecords[tokenId][_record];
  }

  function getNameStringRecordsList(uint256 tokenId) external view override returns (string[] memory) {
    return wrldStringRecordsList[tokenId];
  }

  function getNameAddressRecord(uint256 tokenId, string calldata _record) external view override returns (AddressRecord memory) {
    return wrldAddressRecords[tokenId][_record];
  }

  function getNameAddressRecordsList(uint256 tokenId) external view override returns (string[] memory) {
    return wrldAddressRecordsList[tokenId];
  }

  function getNameUintRecord(uint256 tokenId, string calldata _record) external view override returns (UintRecord memory) {
    return wrldUintRecords[tokenId][_record];
  }

  function getNameUintRecordsList(uint256 tokenId) external view override returns (string[] memory) {
    return wrldUintRecordsList[tokenId];
  }

  function getNameIntRecord(uint256 tokenId, string calldata _record) external view override returns (IntRecord memory) {
    return wrldIntRecords[tokenId][_record];
  }

  function getNameIntRecordsList(uint256 tokenId) external view override returns (string[] memory) {
    return wrldIntRecordsList[tokenId];
  }


}