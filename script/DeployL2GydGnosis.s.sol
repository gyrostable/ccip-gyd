// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydGnosis is L2GydDeploymentScript {
  // CCIP router (Gnosis)
  // https://gnosisscan.io/address/0x4aAD6071085df840abD9Baf1697d5D5992bDadce
  address ccipRouter = 0x4aAD6071085df840abD9Baf1697d5D5992bDadce;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
