// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service.sol";

contract WRLD_NameService_Resolver_V1 is IWRLD_Name_Service_Resolver {
  IWRLD_Name_Service nameService;

  mapping(uint256 => mapping(string => StringRecord)) private wrldNameStringRecords;
  mapping(uint256 => string[]) private wrldNameStringRecordsList;

  mapping(uint256 => mapping(string => AddressRecord)) private wrldNameAddressRecords;
  mapping(uint256 => string[]) private wrldNameAddressRecordsList;

  mapping(uint256 => mapping(string => UintRecord)) private wrldNameUintRecords;
  mapping(uint256 => string[]) private wrldNameUintRecordsList;

  mapping(uint256 => mapping(string => IntRecord)) private wrldNameIntRecords;
  mapping(uint256 => string[]) private wrldNameIntRecordsList;

  constructor(address _nameService) {
    nameService = IWRLD_Name_Service(_nameService);
  }

  /******************
   * Record Setters *
   ******************/

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external override isOwnerOrController(_name) {
    wrldNameStringRecords[_getNameTokenId(_name)][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    wrldNameStringRecordsList[_getNameTokenId(_name)].push(_record);

    emit StringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl);
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external override isOwnerOrController(_name) {
    wrldNameAddressRecords[_getNameTokenId(_name)][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameAddressRecordsList[_getNameTokenId(_name)].push(_record);

    emit AddressRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external override isOwnerOrController(_name) {
    wrldNameUintRecords[_getNameTokenId(_name)][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameUintRecordsList[_getNameTokenId(_name)].push(_record);

    emit UintRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external override isOwnerOrController(_name) {
    wrldNameIntRecords[_getNameTokenId(_name)][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameIntRecordsList[_getNameTokenId(_name)].push(_record);

    emit IntRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  /******************
   * Record Getters *
   ******************/

  function getNameStringRecord(string calldata _name, string calldata _record) external view override returns (StringRecord memory) {
    return wrldNameStringRecords[_getNameTokenId(_name)][_record];
  }

  function getNameStringRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameStringRecordsList[_getNameTokenId(_name)];
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external view override returns (AddressRecord memory) {
    return wrldNameAddressRecords[_getNameTokenId(_name)][_record];
  }

  function getNameAddressRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameAddressRecordsList[_getNameTokenId(_name)];
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external view override returns (UintRecord memory) {
    return wrldNameUintRecords[_getNameTokenId(_name)][_record];
  }

  function getNameUintRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameUintRecordsList[_getNameTokenId(_name)];
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external view override returns (IntRecord memory) {
    return wrldNameIntRecords[_getNameTokenId(_name)][_record];
  }

  function getNameIntRecordsList(string calldata _name) external view override returns (string[] memory) {
    return wrldNameIntRecordsList[_getNameTokenId(_name)];
  }

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Resolver).interfaceId;
  }

  /***********
   * Helpers *
   ***********/

  function _getNameTokenId(string memory _name) private view returns (uint256) {
    return nameService.getNameTokenId(_name);
  }

  /*************
   * Modifiers *
   *************/

  modifier isOwnerOrController(string memory _name) {
    require((nameService.getNameOwner(_name) == msg.sender || nameService.getNameController(_name) == msg.sender), "Sender is not owner or controller");
    _;
  }
}
