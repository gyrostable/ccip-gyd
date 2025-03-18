// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiSei is L2GyfiDeploymentScript {
  // CCIP router (Sei)
  // https://seitrace.com/address/0xAba60dA7E88F7E8f5868C2B6dE06CB759d693af0
  address ccipRouter = 0xAba60dA7E88F7E8f5868C2B6dE06CB759d693af0;

  function run() public returns (address proxy) {
    IGyfiBridge.ChainData[] memory chains = new IGyfiBridge.ChainData[](4);
    chains[0] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.MAINNET,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: escrowAddress,
        gasLimit: gasLimit
      })
    });
    chains[1] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.ARBITRUM,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[2] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.BASE,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[3] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.OPTIMISM,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });

    return _deploy(ccipRouter, chains);
  }
}
