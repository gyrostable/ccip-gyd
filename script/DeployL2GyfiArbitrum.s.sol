// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GyfiDeploymentScript} from "./L2GyfiDeploymentScript.sol";

contract DeployL2Gyfi is L2GyfiDeploymentScript {
  // CCIP router (Arbitrum)
  // https://arbiscan.io/address/0x141fa059441E0ca23ce184B6A78bafD2A517DdE8
  address ccipRouter = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
