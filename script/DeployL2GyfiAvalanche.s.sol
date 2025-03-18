// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiAvalanche is L2GyfiDeploymentScript {
  // CCIP router (Avalanche)
  // https://snowtrace.io/address/0xF4c7E640EdA248ef95972845a62bdC74237805dB
  address ccipRouter = 0xF4c7E640EdA248ef95972845a62bdC74237805dB;

  function run() public returns (address proxy) {
    IGyfiBridge.ChainData[] memory chains = new IGyfiBridge.ChainData[](6);
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
      chainSelector: CCIPSelectors.POLYGON,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[4] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.GNOSIS,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[5] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.OPTIMISM,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });

    return _deploy(ccipRouter, chains);
  }
}
