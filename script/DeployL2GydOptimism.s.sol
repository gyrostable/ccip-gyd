// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydOptimism is L2GydDeploymentScript {
  // CCIP router (Optimism)
  // https://optimistic.etherscan.io/address/0x3206695CaE29952f4b0c22a169725a865bc8Ce0f
  address ccipRouter = 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
