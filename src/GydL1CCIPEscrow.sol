// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Initializable} from "upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {AccessControlDefaultAdminRulesUpgradeable} from
  "upgradeable/access/extensions/AccessControlDefaultAdminRulesUpgradeable.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {Address} from "oz/utils/Address.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";
import {Client} from "ccip/libraries/Client.sol";
import {CCIPReceiverUpgradeable} from "./CCIPReceiverUpgradeable.sol";

import {CCIPHelpers} from "./CCIPHelpers.sol";

/**
 * @title GydL1CCipEscrow
 * @notice Main smart contract to bridge GYD from Ethereum using Chainlink CCIP
 */
contract GydL1CCIPEscrow is
  Initializable,
  UUPSUpgradeable,
  AccessControlDefaultAdminRulesUpgradeable,
  CCIPReceiverUpgradeable
{
  using SafeERC20 for IERC20;
  using Address for address;
  using Address for address payable;

  struct ChainMetadata {
    address gydAddress;
    uint256 gasLimit;
  }

  struct ChainData {
    uint64 chainSelector;
    ChainMetadata metadata;
  }

  /// @notice GYD contract
  IERC20 public gyd;

  /// @notice CCIP router contract
  IRouterClient public router;

  /// @notice Mapping from chain selector to chain metadata (mainly GYD
  /// contract address)
  /// Only chains in this mapping can be bridged to
  mapping(uint64 => ChainMetadata) public chainsMetadata;

  /// @notice The total amount of GYD bridged per chain
  mapping(uint64 => uint256) public totalBridgedGYD;

  /// @notice This event is emitted when a new chain is added
  event ChainAdded(
    uint64 indexed chainSelector, address indexed gydAddress, uint256 gasLimit
  );

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

  /// @notice Disable initializer on deploy
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice GydL1Escrow initializer
   * @param _adminAddress The admin address
   * @param _gydAddress The GYD address
   * @param _routerAddress The CCIP router address
   */
  function initialize(
    address _adminAddress,
    address _gydAddress,
    address _routerAddress,
    ChainData[] memory chains
  ) public initializer {
    __AccessControlDefaultAdminRules_init(3 days, _adminAddress);
    __UUPSUpgradeable_init();
    __CCIPReceiverUpgradeable_init(_routerAddress);

    gyd = IERC20(_gydAddress);
    router = IRouterClient(_routerAddress);
    for (uint256 i; i < chains.length; i++) {
      chainsMetadata[chains[i].chainSelector] = chains[i].metadata;
      emit ChainAdded(
        chains[i].chainSelector,
        chains[i].metadata.gydAddress,
        chains[i].metadata.gasLimit
      );
    }
  }

  /**
   * @dev The GydL1Escrow can only be upgraded by the owner
   * @param v new GydL1Escrow implementation
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
   * @param gydAddress the GYD contract address on the chain
   */
  function addChain(uint64 chainSelector, address gydAddress, uint256 gasLimit)
    external
    onlyRole(DEFAULT_ADMIN_ROLE)
  {
    chainsMetadata[chainSelector] = ChainMetadata(gydAddress, gasLimit);
    emit ChainAdded(chainSelector, gydAddress, gasLimit);
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
   * @notice Bridge GYD from Ethereum mainnet to the specified chain
   * @param recipient The recipient of the bridged token
   * @param amount GYD amount
   * @param data calldata for the recipient on the destination chain
   */
  function bridgeToken(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount,
    bytes memory data
  ) public payable virtual {
    gyd.safeTransferFrom(msg.sender, address(this), amount);

    ChainMetadata memory chainMeta = chainsMetadata[destinationChainSelector];
    if (chainMeta.gydAddress == address(0)) {
      revert ChainNotSupported(destinationChainSelector);
    }

    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      chainMeta.gydAddress, recipient, amount, data, chainMeta.gasLimit
    );
    uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    CCIPHelpers.sendCCIPMessage(
      router, destinationChainSelector, evm2AnyMessage, fees
    );

    uint256 bridged = totalBridgedGYD[destinationChainSelector];
    bridged += amount;
    totalBridgedGYD[destinationChainSelector] = bridged;
    emit GYDBridged(destinationChainSelector, msg.sender, amount, bridged);
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
    if (chainMeta.gydAddress == address(0)) {
      revert ChainNotSupported(destinationChainSelector);
    }

    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      chainMeta.gydAddress, recipient, amount, data, chainMeta.gasLimit
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
    address expectedSender =
      chainsMetadata[any2EvmMessage.sourceChainSelector].gydAddress;
    if (expectedSender == address(0)) {
      revert ChainNotSupported(any2EvmMessage.sourceChainSelector);
    }
    address actualSender = abi.decode(any2EvmMessage.sender, (address));
    if (expectedSender != actualSender) {
      revert MessageInvalid();
    }

    (address recipient, uint256 amount, bytes memory data) =
      abi.decode(any2EvmMessage.data, (address, uint256, bytes));
    uint256 bridged = totalBridgedGYD[any2EvmMessage.sourceChainSelector];
    bridged -= amount;
    totalBridgedGYD[any2EvmMessage.sourceChainSelector] = bridged;

    gyd.safeTransfer(recipient, amount);
    if (data.length > 0) {
      recipient.functionCall(data);
    }

    emit GYDClaimed(
      any2EvmMessage.sourceChainSelector, recipient, amount, bridged
    );
  }
}
