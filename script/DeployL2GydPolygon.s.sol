// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {L2GydDeploymentScript} from "./L2GydDeploymentScript.sol";

contract DeployL2GydPolygon is L2GydDeploymentScript {
  // CCIP router (Polygon)
  // https://polygonscan.com/address/0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe
  address ccipRouter = 0x849c5ED5a80F5B408Dd4969b78c2C8fdf0565Bfe;

  function run() public returns (address proxy) {
    return _deploy(ccipRouter);
  }
}
