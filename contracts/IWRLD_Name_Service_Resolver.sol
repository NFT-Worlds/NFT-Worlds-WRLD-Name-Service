// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Resolver is IERC165 {
  struct StringRecord {
    string value;
    uint256 ttl;
  }

  struct AddressRecord {
    address value;
    uint256 ttl;
  }

  struct UintRecord {
    uint256 value;
    uint256 ttl;
  }

  struct IntRecord {
    int256 value;
    uint256 ttl;
  }

  function getNameStringRecord(string calldata _name, string calldata _record) external view returns (StringRecord memory);
  function getNameStringRecordsList(string calldata _name) external view returns (string[] memory);

  function getNameAddressRecord(string calldata _name, string calldata _record) external view returns (AddressRecord memory);
  function getNameAddressRecordsList(string calldata _name) external view returns (string[] memory);

  function getNameUintRecord(string calldata _name, string calldata _record) external view returns (UintRecord memory);
  function getNameUintRecordsList(string calldata _name) external view returns (string[] memory);

  function getNameIntRecord(string calldata _name, string calldata _record) external view returns (IntRecord memory);
  function getNameIntRecordsList(string calldata _name) external view returns (string[] memory);
}
