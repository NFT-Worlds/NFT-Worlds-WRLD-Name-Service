// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

interface IWRLD_Name_Service_Bridge is IERC165 {
  event NameBridged(uint256 indexed tokenId, address registerer, uint96 expiresAt);

  function nameTokenId(string memory name) external pure returns (uint256);
  function registererOf(uint256 tokenId) external view returns (address);
  function controllerOf(uint256 tokenId) external view returns (address);
  function expiryOf(uint256 tokenId) external view returns (uint96);
  function nameOf(uint256 tokenId) external view returns (string memory);

}
