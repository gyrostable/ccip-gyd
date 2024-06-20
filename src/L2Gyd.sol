// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

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

/**
 * @title L2Gyd
 * @notice GYD contract on L2s that support CCIP. Allows to burn and bridge
 * back GYD too
 */
contract L2Gyd is
  Initializable,
  UUPSUpgradeable,
  Ownable2StepUpgradeable,
  ERC20Upgradeable,
  CCIPReceiverUpgradeable
{
  /// @notice The CCIP router contract
  IRouterClient public router;

  /// @notice GydL1Escrow contract address on Ethereum mainnet
  address public destAddress;

  /// @notice Gas limit when bridging to the GydL1Escrow
  uint256 public bridgeGasLimit;

  /// @notice Chain selector of Ethereum mainnet on CCIP
  uint64 public mainnetChainSelector;

  /// @notice This event is emitted when the GYD is bridged
  event GYDBridged(address indexed bridger, uint256 amount, uint256 total);

  /// @notice This event is emitted when the GYD is claimed
  event GYDClaimed(address indexed bridger, uint256 amount, uint256 total);

  /// @notice This event is emitted when the gas limit is updated
  event GasLimitUpdated(uint256 gasLimit);

  /// @notice This error is raised if message from the bridge is invalid
  error MessageInvalid();

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
   * @param _destAddress The contract address of GydL1Escrow
   * @param _chainSelector The chain selector of Ethereum mainnet on CCIP
   * @param _bridgeGasLimit The gas limit when bridging to the GydL1Escrow
   */
  function initialize(
    address _ownerAddress,
    address _routerAddress,
    address _destAddress,
    uint64 _chainSelector,
    uint256 _bridgeGasLimit
  ) public initializer {
    __Ownable2Step_init();
    __UUPSUpgradeable_init();
    __ERC20_init("Gyro Dollar", "GYD");
    __CCIPReceiverUpgradeable_init(_routerAddress);

    _transferOwnership(_ownerAddress);
    router = IRouterClient(_routerAddress);
    destAddress = _destAddress;
    mainnetChainSelector = _chainSelector;
    bridgeGasLimit = _bridgeGasLimit;
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
   * @notice Bridge GYD from the current chain to Ethereum mainnet
   * @param recipient The recipient of the bridged token
   * @param amount GYD amount
   */
  function bridgeToken(address recipient, uint256 amount)
    public
    payable
    virtual
  {
    _burn(msg.sender, amount);
    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      destAddress, recipient, amount, bridgeGasLimit
    );
    uint256 fees = router.getFee(mainnetChainSelector, evm2AnyMessage);
    CCIPHelpers.sendCCIPMessage(
      router, mainnetChainSelector, evm2AnyMessage, fees
    );

    emit GYDBridged(msg.sender, amount, totalSupply());
  }

  function getFee(address recipient, uint256 amount)
    external
    view
    returns (uint256)
  {
    Client.EVM2AnyMessage memory evm2AnyMessage = CCIPHelpers.buildCCIPMessage(
      destAddress, recipient, amount, bridgeGasLimit
    );
    return router.getFee(mainnetChainSelector, evm2AnyMessage);
  }

  /**
   * Updates the gas limit when bridging to a chain
   * @param gasLimit the new gas limit for this chain
   */
  function updateGasLimit(uint256 gasLimit) external onlyOwner {
    bridgeGasLimit = gasLimit;
    emit GasLimitUpdated(gasLimit);
  }

  /// @dev handle a received message
  /// the authentification is done in the parent contract
  function _ccipReceive(Client.Any2EVMMessage memory any2EvmMessage)
    internal
    override
  {
    if (any2EvmMessage.sourceChainSelector != mainnetChainSelector) {
      revert MessageInvalid();
    }
    address actualSender = abi.decode(any2EvmMessage.sender, (address));
    if (actualSender != destAddress) {
      revert MessageInvalid();
    }

    (address recipient, uint256 amount) =
      abi.decode(any2EvmMessage.data, (address, uint256));
    _mint(recipient, amount);

    emit GYDClaimed(recipient, amount, totalSupply());
  }
}
