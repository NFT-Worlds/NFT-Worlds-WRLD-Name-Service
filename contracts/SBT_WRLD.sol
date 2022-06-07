// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "./ERC4973Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "./IWRLD_Name_Service_Bridge.sol";

contract SBT_WRLD is Initializable, OwnableUpgradeable, ERC4973Upgradeable {
  IWRLD_Name_Service_Bridge wnsBridge;  // TODO: change to immutable for deployment

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(string memory name_, string memory symbol_) {
    __Ownable_init();
    __ERC4973_init(name_, symbol_);
  }

  function ownerOf(uint256 tokenId) public view virtual override returns (address) {
    address owner = _owners[tokenId];
    require(owner != address(0), "ownerOf: token doesn't exist");
    return wnsBridge.registererOf(uint256(owner));
  }

  function mint(address to, uint256 tokenId, string memory uri) onlyOwner external virtual override returns (uint256) {
    return super._mint(to, tokenId, uri);
  }

  function burn(uint256 tokenId) onlyOwner external virtual override {
    super._burn(tokenId);
  }

}


// Function that can be added to the smart contract:

// [] Being able to revoke (burn) an ABT. Give revocability control to the owner of the contract and to the soul
// [] Being able to reassign an ABT to another account. Give reassignability control to the owner of the contract
// [] Add a mapping (tokenID => counter) and a public function Endorsment so people can come and espress an endorsment and signal value for a specifc SBT.
// [] Add vesting property to the SBT.
