// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseChildTunnel.sol";

import "./IWRLD_Name_Service_Bridge.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Bridge is IWRLD_Name_Service_Bridge, Ownable, FxBaseChildTunnel {
  using StringUtils for *;
  
  struct WRLDName {
    address registerer;
    address controller;
    uint96 expiresAt;
    string name;
  }

  mapping(uint256 => WRLDName) public wrldNames;

  // Polygon fx bridge
  
  function setFxRootTunnel(address _fxRootTunnel) external override onlyOwner {
    fxRootTunnel = _fxRootTunnel;
  }

  function _processMessageFromRoot(uint256 , address sender, bytes memory data) internal override validateSender(sender) {
    uint256 tokenId = uint256(data[0:31]);
    uint96 expiresAt = uint96(data[32:43]);
    address registerer = address(data[44:63]);
	  wrldNames[tokenId] = WRLDName(registerer, address(0), expiresAt, "");
    emit NameBridged(tokenId, registerer, expiresAt);
  }

  // Set records
  function setController(uint256 tokenId, address controller) external {
    require(msg.sender == wrldNames[tokenId].registerer, "Access denied");
    wrldNames[tokenId].controller = controller;
  }

  function setName(uint256 tokenId, string calldata name) external {
    require(msg.sender == wrldNames[tokenId].registerer || msg.sender == wrldNames[tokenId].controller, "Access denied");
    require(nameTokenId(name) == tokenId, "Wrong name");
    wrldNames[tokenId].name = name;
  }

  // ######## Views ########

  function nameTokenId(string memory name) public pure override returns (uint256){
    return uint256(uint160(uint256(keccak256(bytes(name)))));
  }

  function registererOf(uint256 tokenId) external view returns (address) {
    return wrldNames[tokenId].registerer;
  }

  function controllerOf(uint256 tokenId) external view returns (address) {
    return wrldNames[tokenId].controller;
  }

  function expiryOf(uint256 tokenId) external view returns (uint96) {
    return wrldNames[tokenId].expiresAt;
  }

  function nameOf(uint256 tokenId) external view returns (string memory) {
    return wrldNames[tokenId].name;
  }

  function isAuthd(uint256 tokenId, address user) external view returns (bool)  {
    return (user == wrldNames[tokenId].registerer || user == wrldNames[tokenId].controller);
  }


}
