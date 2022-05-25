// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IWRLD_Records.sol";

interface IWRLD_Name_Service_Resolver is IERC165, IWRLD_Records {
  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external;
  function getNameStringRecord(string calldata _name, string calldata _record) external view returns (StringRecord memory);
  function getNameStringRecordsList(string calldata _name) external view returns (string[] memory);

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external;
  function getNameAddressRecord(string calldata _name, string calldata _record) external view returns (AddressRecord memory);
  function getNameAddressRecordsList(string calldata _name) external view returns (string[] memory);

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external;
  function getNameUintRecord(string calldata _name, string calldata _record) external view returns (UintRecord memory);
  function getNameUintRecordsList(string calldata _name) external view returns (string[] memory);

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external;
  function getNameIntRecord(string calldata _name, string calldata _record) external view returns (IntRecord memory);
  function getNameIntRecordsList(string calldata _name) external view returns (string[] memory);

  event StringRecordUpdated(string indexed idxName, string name, string record, string value, string typeOf, uint256 ttl);
  event AddressRecordUpdated(string indexed idxName, string name, string record, address value, uint256 ttl);
  event UintRecordUpdated(string indexed idxName, string name, string record, uint256 value, uint256 ttl);
  event IntRecordUpdated(string indexed idxName, string name, string record, int256 value, uint256 ttl);
}
