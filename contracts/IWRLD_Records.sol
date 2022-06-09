// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWRLD_Records {
  struct StringRecord {
    string value;
    string typeOf;
    uint32 ttl;
  }

  struct AddressRecord {
    address value;
    uint32 ttl;
  }

  struct UintRecord {
    uint256 value;
    uint32 ttl;
  }

  struct IntRecord {
    int256 value;
    uint32 ttl;
  }

}
