// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

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

  function getNameStringRecord(bytes32 _name, bytes32 _record) external view returns (StringRecord memory);
  function getNameAddressRecord(bytes32 _name, bytes32 _record) external view returns (AddressRecord memory);
  function getNameUintRecord(bytes32 _name, bytes32 _record) external view returns (UintRecord memory);
  function getNameIntRecord(bytes32 _name, bytes32 _record) external view returns (IntRecord memory);
}
