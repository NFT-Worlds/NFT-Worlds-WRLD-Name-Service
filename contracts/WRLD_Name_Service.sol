// SPDX-License-Identifier: MIT
pragma solidity 0.8.2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "./IWRLD_Name_Service_Resolver.sol";

contract WRLD_Name_Service is IWRLD_Name_Service_Resolver, ERC721, Ownable, ReentrancyGuard {
  using Strings for uint256;
  using Counters for Counters.Counter;

  IERC20 immutable wrld;

  uint256 private constant YEAR_SECONDS = 31536000;

  uint256 public annualWrldPrice = 500 ether; // $WRLD
  mapping(uint256 => WRLDName) public wrldNames;
  mapping(bytes32 => uint256) public nameTokenId;

  mapping(uint256 => mapping(bytes32 => AddressRecord)) private wrldNameAddressRecords;
  mapping(uint256 => bytes32[]) private wrldNameAddressRecordsList;

  mapping(uint256 => mapping(bytes32 => StringRecord)) private wrldNameStringRecords;
  mapping(uint256 => bytes32[]) private wrldNameStringRecordsList;

  mapping(uint256 => mapping(bytes32 => UintRecord)) private wrldNameUintRecords;
  mapping(uint256 => bytes32[]) private wrldNameUintRecordsList;

  mapping(uint256 => mapping(bytes32 => IntRecord)) private wrldNameIntRecords;
  mapping(uint256 => bytes32[]) private wrldNameIntRecordsList;

  Counters.Counter public tokenSupply;

  struct WRLDName {
    bytes32 name;
    address controller;
    IWRLD_Name_Service_Resolver alternateResolver;
    uint256 expiresAt;
  }

  constructor(address _wrld) ERC721("WRLD Name Service", "WNS") {
    wrld = IERC20(_wrld);
  }

  /************
   * Metadata *
   ************/

  function tokenURI(uint256 _tokenId) override public view returns (string memory) {

  }

  /****************
   * Registration *
   ****************/

  function register(bytes32[] calldata _names, uint8[] calldata _registrationYears) external nonReentrant {
    require(_names.length == _registrationYears.length, "Arg size mismatched");

    uint256 sumYears = 0;

    for (uint256 i = 0; i < _names.length; i++) {
      require(getNameExpiration(_names[i]) < block.timestamp, "Unavailable name");
      require(_registrationYears[i] > 0, "Years must be greater than 0");

      tokenSupply.increment(); // must start at 1

      wrldNames[tokenSupply.current()] = WRLDName({
        name: _names[i],
        controller: msg.sender,
        alternateResolver: IWRLD_Name_Service_Resolver(address(0)),
        expiresAt: block.timestamp + YEAR_SECONDS * _registrationYears[i]
      });

      nameTokenId[_names[i]] = tokenSupply.current();

      _safeMint(msg.sender, tokenSupply.current());

      sumYears += _registrationYears[i];
    }

    wrld.transferFrom(msg.sender, address(this), sumYears * annualWrldPrice);
  }

  function extendRegistration(bytes32[] calldata _names, uint8[] calldata _additionalYears) external {
    require(_names.length == _additionalYears.length, "Arg size mismatched");

    uint256 sumYears = 0;

    for (uint256 i = 0; i < _names.length; i++) {
      require(_additionalYears[i] > 0, "Years must be greater than zero");

      WRLDName storage wrldName = wrldNames[nameTokenId[_names[i]]];
      wrldName.expiresAt = wrldName.expiresAt + YEAR_SECONDS * _additionalYears[i];

      sumYears += _additionalYears[i];
    }

    wrld.transferFrom(msg.sender, address(this), sumYears * annualWrldPrice);
  }

  /***********
   * Resolve *
   ***********/

  function nameExists(bytes32 _name) external view returns (bool) {
    return nameTokenId[_name] != 0;
  }

  function nameAlternateResolverExists(bytes32 _name) public view returns (bool) {
    return address(wrldNames[nameTokenId[_name]].alternateResolver) != address(0);
  }

  function getTokenName(uint256 _tokenId) external view returns (bytes32) {
    return wrldNames[_tokenId].name;
  }

  function getName(bytes32 _name) external view returns (WRLDName memory) {
    return wrldNames[nameTokenId[_name]];
  }

  function getNameOwner(bytes32 _name) public view returns (address) {
    return ownerOf(nameTokenId[_name]);
  }

  function getNameController(bytes32 _name) public view returns (address) {
    return wrldNames[nameTokenId[_name]].controller;
  }

  function getNameExpiration(bytes32 _name) public view returns (uint256) {
    return wrldNames[nameTokenId[_name]].expiresAt;
  }

  function getNameAddressRecord(bytes32 _name, bytes32 _record) external view virtual override returns (AddressRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameAddressRecord(_name, _record)
      : wrldNameAddressRecords[nameTokenId[_name]][_record];
  }

  function getNameAddressRecordsList(bytes32 _name) external view virtual override returns (bytes32[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameAddressRecordsList(_name)
      : wrldNameAddressRecordsList[nameTokenId[_name]];
  }

  function getNameStringRecord(bytes32 _name, bytes32 _record) external view virtual override returns (StringRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameStringRecord(_name, _record)
      : wrldNameStringRecords[nameTokenId[_name]][_record];
  }

  function getNameStringRecordsList(bytes32 _name) external view virtual override returns (bytes32[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameStringRecordsList(_name)
      : wrldNameStringRecordsList[nameTokenId[_name]];
  }

  function getNameUintRecord(bytes32 _name, bytes32 _record) external view virtual override returns (UintRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameUintRecord(_name, _record)
      : wrldNameUintRecords[nameTokenId[_name]][_record];
  }

  function getNameUintRecordsList(bytes32 _name) external view virtual override returns (bytes32[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameUintRecordsList(_name)
      : wrldNameUintRecordsList[nameTokenId[_name]];
  }

  function getNameIntRecord(bytes32 _name, bytes32 _record) external view virtual override returns (IntRecord memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameIntRecord(_name, _record)
      : wrldNameIntRecords[nameTokenId[_name]][_record];
  }

  function getNameIntRecordsList(bytes32 _name) external view virtual override returns (bytes32[] memory) {
    return (nameAlternateResolverExists(_name))
      ? wrldNames[nameTokenId[_name]].alternateResolver.getNameIntRecordsList(_name)
      : wrldNameIntRecordsList[nameTokenId[_name]];
  }

  /***********
   * Control *
   ***********/

  function setController(bytes32 _name, address _controller) external {
    require(getNameOwner(_name) == msg.sender, "Sender is not controller or owner");

    wrldNames[nameTokenId[_name]].controller = _controller;
  }

  function setAlternateResolver(bytes32 _name, address _alternateResolver) external {
    IWRLD_Name_Service_Resolver resolver = IWRLD_Name_Service_Resolver(_alternateResolver);

    require(resolver.supportsInterface(type(IWRLD_Name_Service_Resolver).interfaceId), "Invalid resolver");

    wrldNames[nameTokenId[_name]].alternateResolver = resolver;
  }

  function setAddressRecord(bytes32 _name, bytes32 _record, address _value, uint256 _ttl) public {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");

    wrldNameAddressRecords[nameTokenId[_name]][_record] = AddressRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameAddressRecordsList[nameTokenId[_name]].push(_record);
  }

  function setStringRecord(bytes32 _name, bytes32 _record, string calldata _value, uint256 _ttl) external {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");

    wrldNameStringRecords[nameTokenId[_name]][_record] = StringRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameStringRecordsList[nameTokenId[_name]].push(_record);
  }

  function setUintRecord(bytes32 _name, bytes32 _record, uint256 _value, uint256 _ttl) external {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");

    wrldNameUintRecords[nameTokenId[_name]][_record] = UintRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameUintRecordsList[nameTokenId[_name]].push(_record);
  }

  function setIntRecord(bytes32 _name, bytes32 _record, int256 _value, uint256 _ttl) external {
    require((getNameOwner(_name) == msg.sender || getNameController(_name) == msg.sender), "Sender is not owner or controller");

    wrldNameIntRecords[nameTokenId[_name]][_record] = IntRecord({
      value: _value,
      ttl: _ttl
    });

    wrldNameIntRecordsList[nameTokenId[_name]].push(_record);
  }

  /*********
   * Owner *
   *********/

  function setAnnualWrldPrice(uint256 _annualWrldPrice) external onlyOwner {
    annualWrldPrice = _annualWrldPrice;
  }

  /**************
   * Withdrawal *
   **************/

  function withdrawWrld(address toAddress) external onlyOwner {
    wrld.transferFrom(address(this), toAddress, wrld.balanceOf(address(this)));
  }

  /*************
   * Overrides *
   *************/

  function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override {
    WRLDName storage wrldName = wrldNames[tokenId];

    wrldName.controller = to;

    super._beforeTokenTransfer(from, to, tokenId);
  }
}
