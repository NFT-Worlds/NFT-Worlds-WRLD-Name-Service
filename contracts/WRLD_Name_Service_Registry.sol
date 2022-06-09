// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

import "./IWRLD_Name_Service_Metadata.sol";
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

  function nameExists(string calldata _name) external view override returns (bool) {
    return _exists(nameTokenId(_name.UTS46Normalize()));
  }

  function getTokenName(uint256 _tokenId) external view override returns (string memory) {
    return wrldNames[_tokenId].name;
  }

  /*********
   * Owner *
   *********/

  function setApprovedRegistrar(address _approvedRegistrar, bool _allow) external onlyOwner {
    approvedRegistrars[_approvedRegistrar] = _allow;
  }

  function setMetadataContract(address _metadata) external onlyOwner {
    IWRLD_Name_Service_Metadata metadataContract = IWRLD_Name_Service_Metadata(_metadata);

    require(metadataContract.supportsInterface(type(IWRLD_Name_Service_Metadata).interfaceId), "Invalid metadata contract");

    metadata = metadataContract;
  }


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

  /**********
   * ERC165 *
   **********/

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
    return interfaceId == type(IWRLD_Name_Service_Registry).interfaceId || super.supportsInterface(interfaceId);
  }

  /*************
   * Modifiers *
   *************/

  modifier isApprovedRegistrar() {
    require(approvedRegistrars[msg.sender], "msg sender is not registrar");
    _;
  }


}
