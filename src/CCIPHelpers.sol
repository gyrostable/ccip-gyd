// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Client} from "ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";
import {Address} from "oz/utils/Address.sol";

import {IGydBridge} from "./IGydBridge.sol";

library CCIPHelpers {
  using Address for address payable;

  error FeesNotCovered(uint256 fees);

  function buildCCIPMessage(
    address gydAddress,
    address recipient,
    uint256 amount,
    bytes memory data,
    uint256 gasLimit
  ) internal pure returns (Client.EVM2AnyMessage memory) {
    bytes memory messageData = abi.encode(recipient, amount, data);
    return Client.EVM2AnyMessage({
      receiver: abi.encode(gydAddress),
      data: messageData,
      tokenAmounts: new Client.EVMTokenAmount[](0),
      extraArgs: Client._argsToBytes(Client.EVMExtraArgsV1({gasLimit: gasLimit})),
      feeToken: address(0)
    });
  }

  function sendCCIPMessage(
    IRouterClient router,
    uint64 destinationChainSelector,
    Client.EVM2AnyMessage memory evm2AnyMessage,
    uint256 fees
  ) internal {
    if (fees > msg.value) {
      revert FeesNotCovered(fees);
    }
    router.ccipSend{value: fees}(destinationChainSelector, evm2AnyMessage);

    uint256 refund = msg.value - fees;
    if (refund > 0) {
      payable(msg.sender).sendValue(refund);
    }
  }

  function validateRateLimit(
    uint64 chainSelector,
    uint256 amount,
    IGydBridge.RateLimitData memory rateLimit,
    IGydBridge.ChainMetadata memory chainMeta
  ) internal view returns (IGydBridge.RateLimitData memory) {
    uint256 ellapsedSinceReplenish = block.timestamp - rateLimit.lastRefill;
    uint256 amountToReplenish = ellapsedSinceReplenish * chainMeta.refillRate;
    uint256 available = rateLimit.available + amountToReplenish;
    if (available > chainMeta.capacity) {
      available = chainMeta.capacity;
    }
    if (available < amount) {
      revert IGydBridge.RateLimitExceeded(chainSelector, amount, available);
    }
    return IGydBridge.RateLimitData({
      available: uint192(available - amount),
      lastRefill: uint64(block.timestamp)
    });
  }
}
