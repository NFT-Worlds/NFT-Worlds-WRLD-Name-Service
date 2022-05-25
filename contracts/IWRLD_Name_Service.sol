// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service is IERC165 {
  function getNameTokenId(string calldata _name) external view returns (uint256);
  function getNameOwner(string memory _name) external view returns (address);
  function getNameController(string memory _name) external view returns (address);

  event NameRegistered(string indexed idxName, string name, uint16 registrationYears);
  event NameRegistrationExtended(string indexed idxName, string name, uint16 additionalYears);
  event NameControllerUpdated(string indexed idxName, string name, address controller);
  event NameResolverUpdated(string indexed idxName, string name, address resolver);

  event ResolverStringRecordUpdated(string indexed idxName, string name, string record, string value, string typeOf, uint256 ttl, address resolver);
  event ResolverAddressRecordUpdated(string indexed idxName, string name, string record, address value, uint256 ttl, address resolver);
  event ResolverUintRecordUpdated(string indexed idxName, string name, string record, uint256 value, uint256 ttl, address resolver);
  event ResolverIntRecordUpdated(string indexed idxName, string name, string record, int256 value, uint256 ttl, address resolver);
}
