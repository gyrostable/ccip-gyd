// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiOptimism is L2GyfiDeploymentScript {
  // CCIP router (Optimism)
  // https://optimistic.etherscan.io/address/0x3206695CaE29952f4b0c22a169725a865bc8Ce0f
  address ccipRouter = 0x3206695CaE29952f4b0c22a169725a865bc8Ce0f;

  function run() public returns (address proxy) {
    IGyfiBridge.ChainData[] memory chains = new IGyfiBridge.ChainData[](8);
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
      chainSelector: CCIPSelectors.AVALANCHE,
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
      chainSelector: CCIPSelectors.POLYGON,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[6] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.SEI,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });
    chains[7] = IGyfiBridge.ChainData({
      chainSelector: CCIPSelectors.SONIC,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2GyfiAddress,
        gasLimit: gasLimit
      })
    });

    return _deploy(ccipRouter, chains);
  }
}
