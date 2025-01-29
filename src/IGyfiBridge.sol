// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGyfiBridge {
  struct ChainMetadata {
    address targetAddress;
    uint256 gasLimit;
  }

  struct ChainData {
    uint64 chainSelector;
    ChainMetadata metadata;
  }

  /// @notice This event is emitted when a new chain is added
  event ChainAdded(
    uint64 indexed chainSelector,
    address indexed targetAddress,
    uint256 gasLimit
  );

  /// @notice This event is emitted when the gas limit is updated
  event GasLimitUpdated(uint64 indexed chainSelector, uint256 gasLimit);

  /// @notice This event is emitted when the GYFI is bridged
  event GYFIBridged(
    uint64 indexed chainSelector,
    address indexed bridger,
    uint256 amount,
    uint256 total
  );

  /// @notice This event is emitted when the GYFI is claimed
  event GYFIClaimed(
    uint64 indexed chainSelector,
    address indexed bridger,
    uint256 amount,
    uint256 total
  );

  /// @notice This error is raised if message from the bridge is invalid
  error MessageInvalid();

  /// @notice This error is raised if the chain is not supported
  error ChainNotSupported(uint64 chainSelector);

  /// @notice This error is raised if the msg value is not enough for the fees
  error FeesNotCovered(uint256 fees);
}
