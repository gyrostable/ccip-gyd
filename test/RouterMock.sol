// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Client} from "ccip/libraries/Client.sol";

/**
 * @title BridgeMock
 * @notice This mock contract is used to make sure passed message are valid
 */
contract RouterMock {
  uint64 public destinationChainSelector;
  address public destAddress;
  address public recipient;
  uint256 public amount;
  uint256 public gasLimit;

  function getFee(uint64, Client.EVM2AnyMessage memory message)
    external
    pure
    returns (uint256 fee)
  {
    (, uint256 amount_) = abi.decode(message.data, (address, uint256));
    return amount_ * 1 / 100;
  }

  function ccipSend(
    uint64 _destinationChainSelector,
    Client.EVM2AnyMessage calldata message
  ) external payable returns (bytes32) {
    destinationChainSelector = _destinationChainSelector;
    destAddress = abi.decode(message.receiver, (address));
    (recipient, amount) = abi.decode(message.data, (address, uint256));
    bytes memory extraArgs = message.extraArgs;
    uint256 gasLimit_;
    assembly {
      gasLimit_ := mload(add(extraArgs, 0x24))
    }
    gasLimit = gasLimit_;
    return "";
  }
}
