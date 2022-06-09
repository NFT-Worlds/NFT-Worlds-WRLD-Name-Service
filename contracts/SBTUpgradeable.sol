// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC4973Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IWRLD_Name_Service_Bridge.sol";

contract SBTUpgradeable is Initializable, OwnableUpgradeable, ERC4973Upgradeable {
  IWRLD_Name_Service_Bridge wnsBridge;  // TODO: change to immutable after deployment

  mapping(uint256 => mapping(uint256 => bytes32)) public properties;
  mapping(uint256 => string) public tags;

  event PropertyUpdated(uint256 indexed tokenId, uint256 indexed property, bytes32 data);

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(string memory name_, string memory symbol_) public initializer {
    __Ownable_init();
    __ERC4973_init(name_, symbol_);
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = super.ownerOf(tokenId);
    return wnsBridge.registererOf(uint256(uint160(owner)));
  }

  function mint(address to, uint256 tokenId, string memory uri) onlyOwner external virtual returns (uint256) {
    return super._mint(to, tokenId, uri);
  }

  function burn(uint256 tokenId) onlyOwner external virtual {
    super._burn(tokenId);
  }

  function setTag(uint256 _property, string calldata _tag) external onlyOwner virtual {
    tags[_property] = _tag;
  }

  function setValues(uint256 tokenId, uint256[] calldata _properties, bytes32[] calldata _values) external onlyOwner virtual {
    require(_properties.length == _values.length, "arg size mismatch");
    for (uint i = 0; i <_properties.length; i++) {
      properties[tokenId][_properties[i]] = _values[i];
      emit PropertyUpdated(tokenId, _properties[i], _values[i]);
    }
  }

}
