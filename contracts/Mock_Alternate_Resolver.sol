// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Resolver.sol";

contract Mock_Alternate_Resolver is IWRLD_Name_Service_Resolver {
  string[] stringRecords = ["test1", "test1"];
  string[] addressRecords = ["test2", "test2"];
  string[] uintRecords = ["test3", "test3"];
  string[] intRecords = ["test4", "test4"];

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external pure override {
    _name; _record; _value; _typeOf; _ttl; // ignore for mock
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external pure override {
    _name; _record; _value; _ttl;
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external pure override {
    _name; _record; _value; _ttl;
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external pure override {
    _name; _record; _value; _ttl;
  }

  function getNameStringRecord(string calldata _name, string calldata _record) external pure override returns (StringRecord memory) {
    _name; _record;
    return StringRecord({
      value: "127.0.0.1",
      typeOf: "A",
      ttl: 1200
    });
  }

  function getNameStringRecordsList(string calldata _name) external view override returns (string[] memory) {
    _name;
    return stringRecords;
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external pure override returns (AddressRecord memory) {
    _name; _record;
    return AddressRecord({
      value: address(0x9A80c6437ad9b6E7a1608814cBab93dEeecf388a),
      ttl: 1200
    });
  }

  function getNameAddressRecordsList(string calldata _name) external view override returns (string[] memory) {
    _name;
    return addressRecords;
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external pure override returns (UintRecord memory) {
    _name; _record;
    return UintRecord({
      value: 123,
      ttl: 1200
    });
  }

  function getNameUintRecordsList(string calldata _name) external view override returns (string[] memory) {
    _name;
    return uintRecords;
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external pure override returns (IntRecord memory) {
    _name; _record;
    return IntRecord({
      value: -123,
      ttl: 1200
    });
  }

  function getNameIntRecordsList(string calldata _name) external view override returns (string[] memory) {
    _name;
    return intRecords;
  }

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    interfaceId;
    return true;
  }
}
