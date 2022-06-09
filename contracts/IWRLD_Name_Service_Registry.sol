// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Registry is IERC165 {
  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external;
  function extendRegistration(uint256[] calldata _tokenIds, uint16[] calldata _additionalYears) external;

  function nameTokenId(string memory name) external pure returns (uint256);
  function nameExists(string calldata _name) external view returns (bool);
  function getTokenName(uint256 _tokenId) external view returns (string memory);

  event NameRegistered(uint256 indexed tokenId, string indexed name, uint16 registrationYears);
  event NameRegistrationExtended(uint256 indexed tokenId, uint16 additionalYears);
  // event NameControllerUpdated(uint256 indexed tokenId, address controller);


  // event ResolverStringEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, string value);
  // event ResolverAddressEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, address value);
  // event ResolverUintEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, uint256 value);
  // event ResolverIntEntryUpdated(address indexed setter, string indexed idxName, string indexed idxEntry, string name, string entry, int256 value);
}
