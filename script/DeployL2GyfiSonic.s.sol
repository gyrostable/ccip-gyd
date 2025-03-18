// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiSonic is L2GyfiDeploymentScript {
  // CCIP router (Sonic)
  // https://sonicscan.org/address/0xB4e1Ff7882474BB93042be9AD5E1fA387949B860
  address ccipRouter = 0xB4e1Ff7882474BB93042be9AD5E1fA387949B860;

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
