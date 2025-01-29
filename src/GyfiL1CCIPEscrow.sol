// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "upgradeable/proxy/utils/Initializable.sol";
import {StorageSlot} from "oz/utils/StorageSlot.sol";
import {UUPSUpgradeable} from "upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
  "upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {Address} from "oz/utils/Address.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";
import {Client} from "ccip/libraries/Client.sol";
import {CCIPReceiverUpgradeable} from "./CCIPReceiverUpgradeable.sol";

import {IGyfiBridge} from "./IGyfiBridge.sol";
import {CCIPHelpers} from "./CCIPHelpers.sol";

/**
 * @title GyfiL1CCipEscrow
 * @notice Main smart contract to bridge GYFI from Ethereum using Chainlink
 * CCIP
 */
contract GyfiL1CCIPEscrow is
  IGyfiBridge,
  Initializable,
  UUPSUpgradeable,
  AccessControlDefaultAdminRulesUpgradeable,
  CCIPReceiverUpgradeable
{
  using SafeERC20 for IERC20;
  using Address for address;
  using Address for address payable;

  /// @notice GYFI contract
  IERC20 public gyfi;

  /// @notice CCIP router contract
  IRouterClient public router;

  /// @notice Mapping from chain selector to chain metadata (mainly GYFI
  /// contract address)
  /// Only chains in this mapping can be bridged to
  mapping(uint64 => ChainMetadata) public chainsMetadata;

  /// @notice The total amount of GYFI bridged per chain
  uint256 public totalBridgedGYFI;

  /// @notice Disable initializer on deploy
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice GyfiL1Escrow initializer
   * @param _adminAddress The admin address
   * @param _gyfiAddress The GYFI address
   * @param _routerAddress The CCIP router address
   */
  function initialize(
    address _adminAddress,
    address _gyfiAddress,
    address _routerAddress,
    ChainData[] memory chains
  ) public initializer {
    __AccessControlDefaultAdminRules_init(3 days, _adminAddress);
    __UUPSUpgradeable_init();
    __CCIPReceiverUpgradeable_init(_routerAddress);

    gyfi = IERC20(_gyfiAddress);
    router = IRouterClient(_routerAddress);
    for (uint256 i; i < chains.length; i++) {
      chainsMetadata[chains[i].chainSelector] = chains[i].metadata;
      emit ChainAdded(
        chains[i].chainSelector,
        chains[i].metadata.targetAddress,
        chains[i].metadata.gasLimit
      );
    }
  }

  /**
   * @dev The GyfiL1Escrow can only be upgraded by the owner
   * @param v new GyfiL1Escrow implementation
   */
  function _authorizeUpgrade(address v)
    internal
    override
    onlyRole(DEFAULT_ADMIN_ROLE)
  {}

  /**
   * @notice Allows the owner to support a new chain
   * @param chainSelector the selector of the chain
   * https://docs.chain.link/ccip/supported-networks/v1_2_0/mainnet#configuration
   * @param gyfiAddress the GYFI contract address on the chain
   */
  function addChain(
    uint64 chainSelector,
    address gyfiAddress,
    uint256 gasLimit
  ) external onlyRole(DEFAULT_ADMIN_ROLE) {
    chainsMetadata[chainSelector] = ChainMetadata(gyfiAddress, gasLimit);
    emit ChainAdded(chainSelector, gyfiAddress, gasLimit);
  }

  /**
   * Updates the gas limit when bridging to a chain
   * @param chainSelector the selector of the chain
   * @param gasLimit the new gas limit for this chain
   */
  function updateGasLimit(uint64 chainSelector, uint256 gasLimit)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    ChainMetadata storage chainMetadata = chainsMetadata[chainSelector];
    chainMetadata.gasLimit = gasLimit;
    emit GasLimitUpdated(chainSelector, gasLimit);
  }

  function bridgeToken(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount
  ) external payable virtual {
    bridgeToken(destinationChainSelector, recipient, amount, "");
  }

  /**
   * @notice Bridge GYFI from Ethereum mainnet to the specified chain
   * @param recipient The recipient of the bridged token
   * @param amount GYFI amount
   * @param data calldata for the recipient on the destination chain
   */
  function bridgeToken(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount,
    bytes memory data
  ) public payable virtual {
    gyfi.safeTransferFrom(msg.sender, address(this), amount);

    ChainMetadata memory chainMeta = chainsMetadata[destinationChainSelector];
    if (chainMeta.targetAddress == address(0)) {
      revert ChainNotSupported(destinationChainSelector);
    }

    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      chainMeta.targetAddress, recipient, amount, data, chainMeta.gasLimit
    );
    uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    CCIPHelpers.sendCCIPMessage(
      router, destinationChainSelector, evm2AnyMessage, fees
    );

    uint256 bridged = totalBridgedGYFI;
    bridged += amount;
    totalBridgedGYFI = bridged;
    emit GYFIBridged(destinationChainSelector, msg.sender, amount, bridged);
  }

  function getFee(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount
  ) external view returns (uint256) {
    return getFee(destinationChainSelector, recipient, amount, "");
  }

  function getFee(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount,
    bytes memory data
  ) public view returns (uint256) {
    ChainMetadata memory chainMeta = chainsMetadata[destinationChainSelector];
    if (chainMeta.targetAddress == address(0)) {
      revert ChainNotSupported(destinationChainSelector);
    }

    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      chainMeta.targetAddress, recipient, amount, data, chainMeta.gasLimit
    );
    return router.getFee(destinationChainSelector, evm2AnyMessage);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    virtual
    override(AccessControlDefaultAdminRulesUpgradeable, CCIPReceiverUpgradeable)
    returns (bool)
  {
    return CCIPReceiverUpgradeable.supportsInterface(interfaceId)
      || AccessControlDefaultAdminRulesUpgradeable.supportsInterface(interfaceId);
  }

  /// @dev handle a received message
  /// the authentification is done in the parent contract
  function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
    internal
    override
  {
    uint64 chainSelector = any2EvmMessage.sourceChainSelector;
    ChainMetadata memory chainMeta = chainsMetadata[chainSelector];
    address expectedSender = chainMeta.targetAddress;

    if (expectedSender == address(0)) revert ChainNotSupported(chainSelector);

    address actualSender = abi.decode(any2EvmMessage.sender, (address));
    if (expectedSender != actualSender) revert MessageInvalid();

    (address recipient, uint256 amount, bytes memory data) =
      abi.decode(any2EvmMessage.data, (address, uint256, bytes));

    uint256 bridged = totalBridgedGYFI;
    bridged -= amount;
    totalBridgedGYFI = bridged;

    gyfi.safeTransfer(recipient, amount);
    if (data.length > 0) {
      recipient.functionCall(data);
    }

    emit GYFIClaimed(
      any2EvmMessage.sourceChainSelector, recipient, amount, bridged
    );
  }
}
