// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

interface IWRLD_Name_Service_MasterBridge {

  function sendMessageToChildren(bytes calldata data) external;

}