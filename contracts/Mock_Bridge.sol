// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "./IWRLD_Name_Service_Bridge.sol";

contract Mock_Bridge is IWRLD_Name_Service_Bridge {
  function transfer(address from, address to, uint256 tokenId, string memory name) external override {}
  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external override {}
  function setController(string calldata _name, address _controller) external override {}

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external override {}
  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external override {}
  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external override {}
  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external override {}

  function setStringEntry(address _setter, string calldata _name, string calldata _entry, string calldata _value) external override {}
  function setAddressEntry(address _setter, string calldata _name, string calldata _entry, address _value) external override {}
  function setUintEntry(address _setter, string calldata _name, string calldata _entry, uint256 _value) external override {}
  function setIntEntry(address _setter, string calldata _name, string calldata _entry, int256 _value) external override {}

  function migrate(string calldata _name, uint256 _networkFlags) external override {}

  function supportsInterface(bytes4 interfaceId) external pure override returns (bool) {
    interfaceId;
    return true;
  }
}
