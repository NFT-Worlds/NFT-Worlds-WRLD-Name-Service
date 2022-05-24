// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Metadata.sol";

contract WRLD_Name_Service_Metadata is IWRLD_Name_Service_Metadata {
  function getMetadata(string calldata _name) external pure override returns (string memory) {
    return _name; // todo, return SVG
  }

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Metadata).interfaceId;
  }
}
