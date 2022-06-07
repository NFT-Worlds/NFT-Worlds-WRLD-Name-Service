// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
//import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

//import "./INFTW_Whitelist.sol";
import "./IWRLD_Name_Service_Metadata.sol";
//import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Registry.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service_Registry is ERC721, IWRLD_Name_Service_Registry, FxBaseRootTunnel, Ownable, ReentrancyGuard {
  using StringUtils for *;

  /**
   * @dev @iamarkdev was here
   * @dev @niftyorca was here
   * */

  IWRLD_Name_Service_Metadata metadata;
  //IWRLD_Name_Service_Resolver resolver;

  uint256 private constant YEAR_SECONDS = 31557600;  // 365.25 days

  mapping(uint256 => WRLDName) public wrldNames;

  // address private approvedWithdrawer;
  mapping(address => bool) private approvedRegistrars;

  struct WRLDName {
    string name;
    //address controller;
    uint96 expiresAt;
  }

  // Polygon fx bridge https://docs.polygon.technology/docs/develop/l1-l2-communication/state-transfer#pre-requisite
  constructor(address _checkpointManager, address _fxRoot)
    ERC721("WRLD Name Service", "WNS")
    FxBaseRootTunnel(_checkpointManager, _fxRoot)
    {}

  /************
   * Metadata *
   ************/

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");
    return metadata.getMetadata(wrldNames[_tokenId].name, wrldNames[_tokenId].expiresAt);
  }

  /****************
   * Registration *
   ****************/

  function register(address _registerer, string[] calldata _names, uint16[] memory _registrationYears) external override isApprovedRegistrar {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    for (uint256 i = 0; i < _names.length; i++) {
      require(_registrationYears[i] > 0 && _registrationYears[i] <= 100, "Years must be between 1 and 100");

      string memory name = _names[i].UTS46Normalize();
      uint96 expiresAt = uint96(block.timestamp + YEAR_SECONDS * _registrationYears[i]); // SafeCast not neccessary for uint96
      uint256 tokenId = nameTokenId(name);  // tokenId is normalized name hashed to an address

      if (_exists(tokenId)) {
        require(wrldNames[tokenId].expiresAt < block.timestamp, "Unavailable name");
        _burn(tokenId);
      } 

      wrldNames[tokenId] = WRLDName(name, expiresAt);
      _safeMint(_registerer, tokenId);

      _sendMessageToChild(abi.encodePacked(tokenId, expiresAt, _registerer)); // (tokenId, expiration, owner)
      emit NameRegistered(tokenId, name, _registrationYears[i]);
      
    }
  }

  /*************
   * Extension *
   *************/
  
  // anyone can extend registration for any domain, including expired ones, as long as fees are retroactively paid
  function extendRegistration(uint256[] calldata _tokenIds, uint16[] calldata _additionalYears) external override isApprovedRegistrar {
    require(_tokenIds.length == _additionalYears.length, "Arg size mismatched");

    for (uint256 i = 0; i < _tokenIds.length; i++) {
      require(_additionalYears[i] > 0 && _additionalYears[i] <= 100, "Years must be between 1 and 100");

      WRLDName storage wrldName = wrldNames[_tokenIds[i]];
      wrldName.expiresAt = wrldName.expiresAt + uint96(YEAR_SECONDS * _additionalYears[i]);

      _sendMessageToChild(abi.encodePacked(_tokenIds[i], wrldName.expiresAt, ownerOf(_tokenIds[i])));
      emit NameRegistrationExtended(_tokenIds[i], _additionalYears[i]);
    }
  }

  /***********
   * Resolve *
   ***********/

  function nameExists(string calldata _name) external view returns (bool) {
    return _exists(nameTokenId(_name.UTS46Normalize()));
  }

  function getTokenName(uint256 _tokenId) external view returns (string memory) {
    return wrldNames[_tokenId].name;
  }

  // function getName(string calldata _name) external view returns (WRLDName memory) {
  //   return wrldNames[nameTokenId(_name.UTS46Normalize())];
  // }

  // function getNameOwner(string memory _name) public view returns (address) {
  //   return ownerOf(nameTokenId(_name));
  // }

  // function getNameController(string memory _name) public view returns (address) {
  //   return wrldNames[nameTokenId(_name)].controller;
  // }

  // function getNameExpiration(string calldata _name) public view returns (uint96) {
  //   return wrldNames[nameTokenId(_name)].expiresAt;
  // }

  // function getNameStringRecord(string calldata _name, string calldata _record) external view returns (StringRecord memory) {
  //   return resolver.getNameStringRecord(_name, _record);
  // }

  // function getNameStringRecordsList(string calldata _name) external view returns (string[] memory) {
  //   return resolver.getNameStringRecordsList(_name);
  // }

  // function getNameAddressRecord(string calldata _name, string calldata _record) external view returns (AddressRecord memory) {
  //   return resolver.getNameAddressRecord(_name, _record);
  // }

  // function getNameAddressRecordsList(string calldata _name) external view returns (string[] memory) {
  //   return resolver.getNameAddressRecordsList(_name);
  // }

  // function getNameUintRecord(string calldata _name, string calldata _record) external view returns (UintRecord memory) {
  //   return resolver.getNameUintRecord(_name, _record);
  // }

  // function getNameUintRecordsList(string calldata _name) external view returns (string[] memory) {
  //   return resolver.getNameUintRecordsList(_name);
  // }

  // function getNameIntRecord(string calldata _name, string calldata _record) external view returns (IntRecord memory) {
  //   return resolver.getNameIntRecord(_name, _record);
  // }

  // function getNameIntRecordsList(string calldata _name) external view returns (string[] memory) {
  //   return resolver.getNameIntRecordsList(_name);
  // }

  // function getStringEntry(address _setter, string calldata _name, string calldata _entry) external view returns (string memory) {
  //   return resolver.getStringEntry(_setter, _name, _entry);
  // }

  // function getAddressEntry(address _setter, string calldata _name, string calldata _entry) external view returns (address) {
  //   return resolver.getAddressEntry(_setter, _name, _entry);
  // }

  // function getUintEntry(address _setter, string calldata _name, string calldata _entry) external view returns (uint256) {
  //   return resolver.getUintEntry(_setter, _name, _entry);
  // }

  // function getIntEntry(address _setter, string calldata _name, string calldata _entry) external view returns (int256) {
  //   return resolver.getIntEntry(_setter, _name, _entry);
  // }

  /***********
   * Control *
   ***********/

  // function setController(uint256 _tokenId, address _controller) external {
  //   require(ownerOf(_tokenId) == msg.sender, "Sender is not owner");

  //   wrldNames[_tokenId].controller = _controller;

  //   emit NameControllerUpdated(_tokenId, _controller);
  // }

  // function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external isOwnerOrController(_name) {
  //   resolver.setStringRecord(_name, _record, _value, _typeOf, _ttl);

  //   emit ResolverStringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl, address(resolver));
  // }

  // function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) external isOwnerOrController(_name) {
  //   resolver.setAddressRecord(_name, _record, _value, _ttl);

  //   emit ResolverAddressRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));
  // }

  // function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external isOwnerOrController(_name) {
  //   resolver.setUintRecord(_name, _record, _value, _ttl);

  //   emit ResolverUintRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));
  // }

  // function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external isOwnerOrController(_name) {
  //   resolver.setIntRecord(_name, _record, _value, _ttl);

  //   emit ResolverIntRecordUpdated(_name, _name, _record, _value, _ttl, address(resolver));
  // }

  /***********
   * Entries *
   ***********/

  // function setStringEntry(string calldata _name, string calldata _entry, string calldata _value) external {
  //   resolver.setStringEntry(msg.sender, _name, _entry, _value);

  //   emit ResolverStringEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);
  // }

  // function setAddressEntry(string calldata _name, string calldata _entry, address _value) external {
  //   resolver.setAddressEntry(msg.sender, _name, _entry, _value);

  //   emit ResolverAddressEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);
  // }

  // function setUintEntry(string calldata _name, string calldata _entry, uint256 _value) external {
  //   resolver.setUintEntry(msg.sender, _name, _entry, _value);

  //   emit ResolverUintEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);
  // }

  // function setIntEntry(string calldata _name, string calldata _entry, int256 _value) external {
  //   resolver.setIntEntry(msg.sender, _name, _entry, _value);

  //   emit ResolverIntEntryUpdated(msg.sender, _name, _entry, _name, _entry, _value);
  // }

  /*********
   * Owner *
   *********/

  // function setApprovedWithdrawer(address _approvedWithdrawer) external onlyOwner {
  //   approvedWithdrawer = _approvedWithdrawer;
  // }

  function setApprovedRegistrar(address _approvedRegistrar, bool _allow) external onlyOwner {
    approvedRegistrars[_approvedRegistrar] = _allow;
  }

  function setMetadataContract(address _metadata) external onlyOwner {
    IWRLD_Name_Service_Metadata metadataContract = IWRLD_Name_Service_Metadata(_metadata);

    require(metadataContract.supportsInterface(type(IWRLD_Name_Service_Metadata).interfaceId), "Invalid metadata contract");

    metadata = metadataContract;
  }

  // function setResolverContract(address _resolver) external onlyOwner {
  //   IWRLD_Name_Service_Resolver resolverContract = IWRLD_Name_Service_Resolver(_resolver);

  //   require(resolverContract.supportsInterface(type(IWRLD_Name_Service_Resolver).interfaceId), "Invalid resolver contract");

  //   resolver = resolverContract;
  // }

  /*************
   * Views *
   *************/

  function nameTokenId(string memory name) public pure override returns (uint256){
    return uint256(uint160(uint256(keccak256(bytes(name)))));
  }

  /*************
   * Overrides *
   *************/

   function ownerOf(uint256 tokenId) public view virtual override returns (address) {
     if (wrldNames[tokenId].expiresAt < block.timestamp) {
       return address(0);
     }
     else {
       return super.ownerOf(tokenId);
     }
   }

   function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal virtual override {
     require(wrldNames[tokenId].expiresAt > block.timestamp || to == address(0), "registration expired");
     _sendMessageToChild(abi.encodePacked(tokenId, wrldNames[tokenId].expiresAt, to));
     super._beforeTokenTransfer(from, to, tokenId);
   }

   function _processMessageFromChild(bytes memory message) virtual internal override{}

  // function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
  //   for (uint256 i = 0; i < quantity; i++) {
  //     WRLDName storage wrldName = wrldNames[startTokenId + i];

  //     wrldName.controller = to;

  //     resolver.setAddressRecord(wrldName.name, "evm_default", to, 3600);
  //     emit ResolverAddressRecordUpdated(wrldName.name, wrldName.name, "evm_default", to, 3600, address(resolver));

  //     super._afterTokenTransfers(from, to, startTokenId, quantity);
  //   }
  // }

  /*************
   * Modifiers *
   *************/

  modifier isApprovedRegistrar() {
    require(approvedRegistrars[msg.sender], "msg sender is not registrar");
    _;
  }

  // modifier isOwnerOrController(string memory _name) {
  //   require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");
  //   _;
  // }
}
