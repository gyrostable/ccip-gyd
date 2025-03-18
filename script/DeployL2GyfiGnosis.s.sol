// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {
  L2GyfiDeploymentScript, IGyfiBridge
} from "./L2GyfiDeploymentScript.sol";
import {CCIPSelectors} from "./Constants.sol";

contract DeployL2GyfiGnosis is L2GyfiDeploymentScript {
  // CCIP router (Gnosis)
  // https://gnosisscan.io/address/0x4aAD6071085df840abD9Baf1697d5D5992bDadce
  address ccipRouter = 0x4aAD6071085df840abD9Baf1697d5D5992bDadce;

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
      chainSelector: CCIPSelectors.AVALANCHE,
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
