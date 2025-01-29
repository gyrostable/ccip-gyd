// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {CCIPSelectors} from "./Constants.sol";

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";

contract DeployL2Gyfi is L2GyfiDeploymentScript {
  // CCIP router (Arbitrum)
  // https://arbiscan.io/address/0x141fa059441E0ca23ce184B6A78bafD2A517DdE8
  address ccipRouter = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;

  function run() public returns (address proxy) {
    // Only support mainnet on deployment
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
