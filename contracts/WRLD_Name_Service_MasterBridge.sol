// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@maticnetwork/fx-portal/contracts/tunnel/FxBaseRootTunnel.sol";

contract WRLD_Name_Service_MasterBridge is Ownable, FxBaseRootTunnel {
  address private registry;

  // Polygon fx bridge https://docs.polygon.technology/docs/develop/l1-l2-communication/state-transfer#pre-requisite
  constructor(address _checkpointManager, address _fxRoot)
    FxBaseRootTunnel(_checkpointManager, _fxRoot)
  {}

  function setRegistry(address _registry) external virtual onlyOwner {
    registry = _registry;
  }

  function sendMessageToChildren(bytes calldata data) external virtual {
    require(msg.sender == registry, "auth failed");
    _sendMessageToChild(data);
  }

  // Overrides
  
  function _processMessageFromChild(bytes memory message) virtual internal override{}

}