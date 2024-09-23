// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydAvalanche is L2GydDeploymentScript {
  // CCIP router (Avalanche)
  // https://snowtrace.io/address/0xF4c7E640EdA248ef95972845a62bdC74237805dB
  address ccipRouter = 0xF4c7E640EdA248ef95972845a62bdC74237805dB;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
