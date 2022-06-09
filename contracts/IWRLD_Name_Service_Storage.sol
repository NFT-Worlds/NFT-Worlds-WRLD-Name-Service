// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

import "./IWRLD_Records.sol";

interface IWRLD_Name_Service_Storage is IERC165, IWRLD_Records {
  event StringRecordUpdated(uint256 indexed tokenId, string record, string value, string typeOf, uint32 ttl);
  event AddressRecordUpdated(uint256 indexed tokenId, string record, address value, uint32 ttl);
  event UintRecordUpdated(uint256 indexed tokenId, string record, uint256 value, uint32 ttl);
  event IntRecordUpdated(uint256 indexed tokenId, string record, int256 value, uint32 ttl);
  event WalletRecordUpdated(uint256 indexed tokenId, uint256 record, string value);

  function setStringRecord(uint256 tokenId, string calldata _record, string calldata _value, string calldata _typeOf, uint32 _ttl) external;
  function setAddressRecord(uint256 tokenId, string calldata _record, address _value, uint32 _ttl) external;
  function setUintRecord(uint256 tokenId, string calldata _record, uint256 _value, uint32 _ttl) external;
  function setIntRecord(uint256 tokenId, string calldata _record, int256 _value, uint32 _ttl) external;
  function setWalletRecord(uint256 tokenId, uint256 _record, string calldata _value) external;
  
  function getStringRecord(uint256 tokenId, string calldata _record) external view returns (StringRecord memory);
  function getAddressRecord(uint256 tokenId, string calldata _record) external view returns (AddressRecord memory);
  function getUintRecord(uint256 tokenId, string calldata _record) external view returns (UintRecord memory);
  function getIntRecord(uint256 tokenId, string calldata _record) external view returns (IntRecord memory);
  function getWalletRecord(uint256 tokenId, uint256 _record) external view returns (string memory);

}