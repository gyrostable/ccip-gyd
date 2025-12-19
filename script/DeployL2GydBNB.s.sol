// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydBase is L2GydDeploymentScript {
  // CCIP router (BNB Chain)
  // https://bscscan.com/address/0x34b03cb9086d7d758ac55af71584f81a598759fe#code
  address ccipRouter = 0x34B03Cb9086d7D758AC55af71584F81A598759FE;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
