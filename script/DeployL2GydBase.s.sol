// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydBase is L2GydDeploymentScript {
  // CCIP router (Base)
  // https://basescan.org/address/0x881e3A65B4d4a04dD529061dd0071cf975F58bCD
  address ccipRouter = 0x881e3A65B4d4a04dD529061dd0071cf975F58bCD;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
