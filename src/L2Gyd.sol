// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {EnumerableMap} from "oz/utils/structs/EnumerableMap.sol";
import {Address} from "oz/utils/Address.sol";
import {Initializable} from "upgradeable/proxy/utils/Initializable.sol";
import {UUPSUpgradeable} from "upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {Ownable2StepUpgradeable} from
  "upgradeable/access/Ownable2StepUpgradeable.sol";
import {ERC20Upgradeable} from "upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {IBridge} from "./IBridge.sol";
import {Client} from "ccip/libraries/Client.sol";
import {IRouterClient} from "ccip/interfaces/IRouterClient.sol";
import {CCIPReceiverUpgradeable} from "./CCIPReceiverUpgradeable.sol";
import {CCIPHelpers} from "./CCIPHelpers.sol";
import {IGydBridge} from "./IGydBridge.sol";

/**
 * @title L2Gyd
 * @notice GYD contract on L2s that support CCIP. Allows to burn and bridge
 * back GYD too
 */
contract L2Gyd is
  IGydBridge,
  Initializable,
  UUPSUpgradeable,
  Ownable2StepUpgradeable,
  ERC20Upgradeable,
  CCIPReceiverUpgradeable
{
  using Address for address;

  /// @notice The CCIP router contract
  IRouterClient public router;

  /// @notice Mapping from chain selector to chain metadata (mainly GYD
  /// contract address)
  /// Only chains in this mapping can be bridged to
  mapping(uint64 => ChainMetadata) public chainsMetadata;

  /// @notice This error is raised if ownership is renounced
  error RenounceInvalid();

  /// @notice Disable initializer on deploy
  constructor() {
    _disableInitializers();
  }

  /**
   * @notice L2Gyd initializer
   * @dev This initializer should be called via UUPSProxy constructor
   * @param _ownerAddress The contract owner
   * @param _routerAddress The CCIP router address
   */
  function initialize(address _ownerAddress, address _routerAddress)
    public
    initializer
  {
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __ERC20_init("Gyro Dollar", "GYD");
    __CCIPReceiverUpgradeable_init(_routerAddress);

    _transferOwnership(_ownerAddress);
    router = IRouterClient(_routerAddress);
  }

  /**
   * @dev The L2Gyd can only be upgraded by the owner
   * @param v new L2Gyd version
   */
  function _authorizeUpgrade(address v) internal override onlyOwner {}

  /**
   * @dev Owner cannot renounce the contract because it is required in order to
   * upgrade the contract
   */
  function renounceOwnership() public virtual override onlyOwner {
    revert RenounceInvalid();
  }

  /**
   * @notice Allows the owner to support a new chain
   * @param chainSelector the selector of the chain
   * https://docs.chain.link/ccip/supported-networks/v1_2_0/mainnet#configuration
   * @param gydAddress the GYD contract address on the chain
   */
  function addChain(uint64 chainSelector, address gydAddress, uint256 gasLimit)
    external
    onlyOwner
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
    onlyOwner
  {
    ChainMetadata storage chainMetadata = chainsMetadata[chainSelector];
    chainMetadata.gasLimit = gasLimit;
    emit GasLimitUpdated(chainSelector, gasLimit);
  }

  function bridgeToken(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount
  ) public payable {
    bridgeToken(destinationChainSelector, recipient, amount, "");
  }

  /**
   * @notice Bridge GYD from the current chain to the given chain
   * @param recipient The recipient of the bridged token
   * @param amount GYD amount
   */
  function bridgeToken(
    uint64 destinationChainSelector,
    address recipient,
    uint256 amount,
    bytes memory data
  ) public payable virtual {
    ChainMetadata memory metadata = chainsMetadata[destinationChainSelector];
    if (metadata.targetAddress == address(0)) {
      revert ChainNotSupported(destinationChainSelector);
    }

    _burn(msg.sender, amount);
    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      metadata.targetAddress, recipient, amount, data, metadata.gasLimit
    );
    uint256 fees = router.getFee(destinationChainSelector, evm2AnyMessage);
    CCIPHelpers.sendCCIPMessage(
      router, destinationChainSelector, evm2AnyMessage, fees
    );

    emit GYDBridged(
      destinationChainSelector, msg.sender, amount, totalSupply()
    );
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

  /// @dev handle a received message
  /// the authentification is done in the parent contract
  function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
    internal
    override
  {
    ChainMetadata memory chainMeta =
      chainsMetadata[any2EvmMessage.sourceChainSelector];
    address actualSender = abi.decode(any2EvmMessage.sender, (address));
    if (actualSender != chainMeta.targetAddress) {
      revert MessageInvalid();
    }

    (address recipient, uint256 amount, bytes memory data) =
      abi.decode(any2EvmMessage.data, (address, uint256, bytes));
    _mint(recipient, amount);
    if (data.length > 0) {
      recipient.functionCall(data);
    }

    emit GYDClaimed(
      any2EvmMessage.sourceChainSelector, recipient, amount, totalSupply()
    );
  }
}
