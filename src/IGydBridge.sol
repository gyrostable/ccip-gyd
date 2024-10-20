// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IGydBridge {
  struct ChainMetadata {
    address targetAddress;
    uint256 gasLimit;
    uint256 capacity;
    uint256 refillRate;
  }

  struct ChainData {
    uint64 chainSelector;
    ChainMetadata metadata;
  }

  struct RateLimitData {
    uint192 available;
    uint64 lastRefill;
  }

  /// @notice This event is emitted when a new chain is set
  event ChainSet(uint64 indexed chainSelector, ChainMetadata metadata);

  /// @notice This event is emitted when the gas limit is updated
  event GasLimitUpdated(uint64 indexed chainSelector, uint256 gasLimit);

  /// @notice This event is emitted when the GYD is bridged
  event GYDBridged(
    uint64 indexed chainSelector,
    address indexed bridger,
    uint256 amount,
    uint256 total
  );

  /// @notice This event is emitted when the GYD is claimed
  event GYDClaimed(
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

  /// @notice This error is raised if the rate limit is exceeded
  error RateLimitExceeded(
    uint64 chainSelector, uint256 requested, uint256 available
  );
}
