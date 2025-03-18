// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiZkevm is L2GyfiDeploymentScript {
  // CCIP router (Zkevm)
  // https://zkevm.polygonscan.com/address/0xA9999937159B293c72e2367Ce314cb3544e7C1a3
  address ccipRouter = 0xA9999937159B293c72e2367Ce314cb3544e7C1a3;

  function run() public returns (address proxy) {
    IGyfiBridge.ChainData[] memory chains = new IGyfiBridge.ChainData[](1);
    chains[0] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.MAINNET,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: escrowAddress,
        gasLimit: gasLimit
      })
    });

    return _deploy(ccipRouter, chains);
  }
}
