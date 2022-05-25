// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./ERC721AF/ERC721AF.sol";
import "./INFTW_Whitelist.sol";
import "./IWRLD_Name_Service_Resolver.sol";
import "./IWRLD_Name_Service_Metadata.sol";
import "./StringUtils.sol";

contract WRLD_Name_Service is ERC721AF, IWRLD_Name_Service_Resolver, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using StringUtils for *;

  /**
   * @dev @iamarkdev was here
   * */

  event NameRegistered(string indexed idxName, string name, uint16 registrationYears);
  event NameRegistrationExtended(string indexed idxName, string name, uint16 additionalYears);
  event NameControllerUpdated(string indexed idxName, string name, address controller);
  event NameResolverUpdated(string indexed idxName, string name, address resolver);

  IERC20 immutable wrld;
  INFTW_Whitelist immutable whitelist;
  IWRLD_Name_Service_Metadata metadata;

  uint256 private constant YEAR_SECONDS = 31536000;
  uint256 private constant PREREGISTRATION_PASS_TYPE_ID = 2;

  bool public registrationEnabled = false;

  uint256[5] public annualWrldPrices = [ 1e70, 1e70, 20000 ether, 2000 ether, 500 ether ]; // $WRLD, 1 char to 5 chars
  mapping(uint256 => WRLDName) public wrldNames;
  mapping(string => uint256) public nameTokenId;

  mapping(uint256 => mapping(string => AddressRecord)) private wrldNameAddressRecords;
  mapping(uint256 => string[]) private wrldNameAddressRecordsList;

  mapping(uint256 => mapping(string => StringRecord)) private wrldNameStringRecords;
  mapping(uint256 => string[]) private wrldNameStringRecordsList;

  mapping(uint256 => mapping(string => UintRecord)) private wrldNameUintRecords;
  mapping(uint256 => string[]) private wrldNameUintRecordsList;

  mapping(uint256 => mapping(string => IntRecord)) private wrldNameIntRecords;
  mapping(uint256 => string[]) private wrldNameIntRecordsList;

  address private approvedWithdrawer;

  struct WRLDName {
    string name;
    address controller;
    IWRLD_Name_Service_Resolver alternateResolver;
    uint256 expiresAt;
  }

  constructor(address _wrld, address _whitelist) ERC721AF("WRLD Name Service", "WNS") {
    wrld = IERC20(_wrld);
    whitelist = INFTW_Whitelist(_whitelist);
  }

  /************
   * Metadata *
   ************/

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {
    require(_exists(_tokenId), "ERC721Metadata: URI query for nonexistent token");

    if (address(metadata) == address(0)) {
      return "";
    }

    return metadata.getMetadata(wrldNames[_tokenId].name, wrldNames[_tokenId].expiresAt);
  }

  /****************
   * Registration *
   ****************/

  function registerWithPass(string[] calldata _names) external nonReentrant {
    bool senderIsOwner = msg.sender == owner();

    if (!senderIsOwner) {
      whitelist.burnTypeForOwnerAddress(PREREGISTRATION_PASS_TYPE_ID, _names.length, msg.sender);
    }

    uint16[] memory registrationYears = new uint16[](_names.length);

    for (uint256 i = 0; i < _names.length; i++) {
      registrationYears[i] = 1;

      if (!senderIsOwner) {
        require(getPrice(_names[i]) < 1000000 ether, "Name not available for sale");
      }
    }

    _register(_names, registrationYears, true);
  }

  function register(string[] calldata _names, uint16[] calldata _registrationYears) external nonReentrant {
    require(registrationEnabled, "Registration is not enabled.");

    _register(_names, _registrationYears, false);
  }

  function _register(string[] calldata _names, uint16[] memory _registrationYears, bool _free) private {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    uint256 mintCount = 0;
    uint256 sumPrice = 0;
    uint256 tokenStartId = _currentIndex;

    for (uint256 i = 0; i < _names.length; i++) {
      require(_registrationYears[i] > 0, "Years must be greater than 0");

      string calldata name = _names[i];
      uint256 expiresAt = block.timestamp + YEAR_SECONDS * _registrationYears[i];

      if (nameExists(name)) {
        require(getNameExpiration(name) < block.timestamp, "Unavailable name");

        uint256 existingTokenId = nameTokenId[name];

        wrldNames[existingTokenId].expiresAt = expiresAt;

        _safeTransferFromForced(getNameOwner(name), msg.sender, existingTokenId, "");
      } else {
        uint256 newTokenId = tokenStartId + mintCount;

        wrldNames[newTokenId] = WRLDName({
          name: name,
          controller: msg.sender,
          alternateResolver: IWRLD_Name_Service_Resolver(address(0)),
          expiresAt: expiresAt
        });

        nameTokenId[name] = newTokenId;

        mintCount++;

        emit NameRegistered(name, name, _registrationYears[i]);
      }

      sumPrice += _registrationYears[i] * getPrice(_names[i]);
    }

    if (mintCount > 0) {
      _safeMint(msg.sender, mintCount);
    }

    if (!_free) {
      wrld.transferFrom(msg.sender, address(this), sumPrice);
    }
  }

  /*************
   * Extension *
   *************/

  function extendRegistration(string[] calldata _names, uint16[] calldata _additionalYears) external {
    require(_names.length == _additionalYears.length, "Arg size mismatched");

    uint256 sumPrice = 0;

    for (uint256 i = 0; i < _names.length; i++) {
      require(_additionalYears[i] > 0, "Years must be greater than zero");

      WRLDName storage wrldName = wrldNames[nameTokenId[_names[i]]];
      wrldName.expiresAt = wrldName.expiresAt + YEAR_SECONDS * _additionalYears[i];

      sumPrice += _additionalYears[i] * getPrice(_names[i]);

      emit NameRegistrationExtended(_names[i], _names[i], _additionalYears[i]);
    }

    wrld.transferFrom(msg.sender, address(this), sumPrice);
  }

  /***********
   * Resolve *
   ***********/

  function nameExists(string calldata _name) public view returns (bool) {
    return nameTokenId[_name] != 0;
  }

  function nameAlternateResolverExists(string calldata _name) public view returns (bool) {
    return address(wrldNames[nameTokenId[_name]].alternateResolver) != address(0);
  }

  function getTokenName(uint256 _tokenId) external view returns (string memory) {
    return wrldNames[_tokenId].name;
  }

  function getName(string calldata _name) external view returns (WRLDName memory) {
    return wrldNames[nameTokenId[_name]];
  }

  function getNameOwner(string memory _name) public view returns (address) {
    return ownerOf(nameTokenId[_name]);
  }

  function getNameController(string memory _name) public view returns (address) {
    return wrldNames[nameTokenId[_name]].controller;
  }

  function getNameExpiration(string calldata _name) public view returns (uint256) {
    return wrldNames[nameTokenId[_name]].expiresAt;
  }

  function getNameAddressRecord(string calldata _name, string calldata _record) external view override returns (AddressRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameAddressRecord(_name, _record)
      : wrldNameAddressRecords[nameTokenId[_name]][_record];
  }

  function getNameAddressRecordsList(string calldata _name) external view override returns (string[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameAddressRecordsList(_name)
      : wrldNameAddressRecordsList[nameTokenId[_name]];
  }

  function getNameStringRecord(string calldata _name, string calldata _record) external view override returns (StringRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameStringRecord(_name, _record)
      : wrldNameStringRecords[nameTokenId[_name]][_record];
  }

  function getNameStringRecordsList(string calldata _name) external view override returns (string[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameStringRecordsList(_name)
      : wrldNameStringRecordsList[nameTokenId[_name]];
  }

  function getNameUintRecord(string calldata _name, string calldata _record) external view override returns (UintRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameUintRecord(_name, _record)
      : wrldNameUintRecords[nameTokenId[_name]][_record];
  }

  function getNameUintRecordsList(string calldata _name) external view override returns (string[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameUintRecordsList(_name)
      : wrldNameUintRecordsList[nameTokenId[_name]];
  }

  function getNameIntRecord(string calldata _name, string calldata _record) external view override returns (IntRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameIntRecord(_name, _record)
      : wrldNameIntRecords[nameTokenId[_name]][_record];
  }

  function getNameIntRecordsList(string calldata _name) external view override returns (string[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameIntRecordsList(_name)
      : wrldNameIntRecordsList[nameTokenId[_name]];
  }

  function getPrice(string calldata _name) internal view returns (uint price) {
    uint len = _name.strlen();
    if (len > 0 && len <= 5) {
      price = annualWrldPrices[len-1];
    } else if (len > 5) {
      price = annualWrldPrices[4];
    } else {
      revert("Invalid name");
    }
  }

  /***********
   * Control *
   ***********/

  function setController(string calldata _name, address _controller) external {
    require(getNameOwner(_name) == msg.sender, "Sender is not owner");

    wrldNames[nameTokenId[_name]].controller = _controller;

    emit NameControllerUpdated(_name, _name, _controller);
  }

  function setAlternateResolver(string calldata _name, address _alternateResolver) external isOwnerOrController(_name) {
    IWRLD_Name_Service_Resolver resolver = IWRLD_Name_Service_Resolver(_alternateResolver);

    require(resolver.supportsInterface(type(IWRLD_Name_Service_Resolver).interfaceId), "Invalid resolver");

    wrldNames[nameTokenId[_name]].alternateResolver = resolver;

    emit NameResolverUpdated(_name, _name, _alternateResolver);
  }

  function setAddressRecord(string memory _name, string memory _record, address _value, uint256 _ttl) public isOwnerOrController(_name) {
    wrldNameAddressRecords[nameTokenId[_name]][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameAddressRecordsList[nameTokenId[_name]].push(_record);

    emit AddressRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setStringRecord(string calldata _name, string calldata _record, string calldata _value, string calldata _typeOf, uint256 _ttl) external isOwnerOrController(_name) {
    wrldNameStringRecords[nameTokenId[_name]][_record] = StringRecord({
      value: _value,
      typeOf: _typeOf,
      ttl: _ttl
    });

    wrldNameStringRecordsList[nameTokenId[_name]].push(_record);

    emit StringRecordUpdated(_name, _name, _record, _value, _typeOf, _ttl);
  }

  function setUintRecord(string calldata _name, string calldata _record, uint256 _value, uint256 _ttl) external isOwnerOrController(_name) {
    wrldNameUintRecords[nameTokenId[_name]][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameUintRecordsList[nameTokenId[_name]].push(_record);

    emit UintRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  function setIntRecord(string calldata _name, string calldata _record, int256 _value, uint256 _ttl) external isOwnerOrController(_name) {
    wrldNameIntRecords[nameTokenId[_name]][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameIntRecordsList[nameTokenId[_name]].push(_record);

    emit IntRecordUpdated(_name, _name, _record, _value, _ttl);
  }

  /*********
   * Owner *
   *********/

  function setAnnualWrldPrices(uint256[] memory _annualWrldPrices) external onlyOwner {
    annualWrldPrices[0] = _annualWrldPrices[0];
    annualWrldPrices[1] = _annualWrldPrices[1];
    annualWrldPrices[2] = _annualWrldPrices[2];
    annualWrldPrices[3] = _annualWrldPrices[3];
    annualWrldPrices[4] = _annualWrldPrices[4];
  }

  function setApprovedWithdrawer(address _approvedWithdrawer) external onlyOwner {
    approvedWithdrawer = _approvedWithdrawer;
  }

  function setMetadataContract(address _metadata) external onlyOwner {
    IWRLD_Name_Service_Metadata metadataContract = IWRLD_Name_Service_Metadata(_metadata);

    require(metadataContract.supportsInterface(type(IWRLD_Name_Service_Metadata).interfaceId), "Invalid metadata contract");

    metadata = metadataContract;
  }

  function enableRegistration() external onlyOwner {
    registrationEnabled = true;
  }

  /**************
   * Withdrawal *
   **************/

  function withdrawWrld(address toAddress) external {
    require(msg.sender == owner() || msg.sender == approvedWithdrawer, "Not approved to withdraw");

    wrld.transfer(toAddress, wrld.balanceOf(address(this)));
  }

  /*************
   * Overrides *
   *************/

  function _startTokenId() internal pure override returns (uint256) {
    return 1; // must start at 1, id 0 is used as non-existant check.
  }

  function _afterTokenTransfers(address from, address to, uint256 startTokenId, uint256 quantity) internal override {
    for (uint256 i = 0; i < quantity; i++) {
      WRLDName storage wrldName = wrldNames[startTokenId + i];

      wrldName.controller = to;

      setAddressRecord(wrldName.name, "evm_default", to, 3600);

      super._afterTokenTransfers(from, to, startTokenId, quantity);
    }
  }

  /*************
   * Modifiers *
   *************/

  modifier isOwnerOrController(string memory _name) {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");
    _;
  }
}
