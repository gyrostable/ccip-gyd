// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";
import {SafeERC20} from "oz/token/ERC20/utils/SafeERC20.sol";
import {Strings} from "oz/utils/Strings.sol";
import {IAccessControl} from "oz/access/IAccessControl.sol";

import {GydL1CCIPEscrow} from "src/GydL1CCIPEscrow.sol";
import {RouterMock} from "./RouterMock.sol";
import {UUPSProxy} from "./UUPSProxy.sol";
import {Client} from "ccip/libraries/Client.sol";

import {CCIPReceiverUpgradeable} from "../src/CCIPReceiverUpgradeable.sol";
import {IGydBridge} from "../src/IGydBridge.sol";

/**
 * @title GydL1EscrowV2Mock
 * @notice Mock contract to test upgradeability of GydL1CCIPEscrow smart
 * contract
 */
contract GydL1EscrowV2Mock is GydL1CCIPEscrow {
  /// @dev Update bridgeToken logic for testing purpose
  function bridgeToken(uint64, address, uint256 amount)
    external
    payable
    virtual
    override
  {
    totalBridgedGYD[0] = 2 * amount;
  }
}

/**
 * @title GydL1EscrowTest
 * @notice Unit tests for GydL1CCIPEscrow
 */
contract GydL1EscrowTest is Test {
  using SafeERC20 for IERC20;

  string ETH_RPC_URL = vm.envString("ETH_RPC_URL");

  address admin = makeAddr("admin");
  address alice = makeAddr("alice");
  address bob = makeAddr("bob");

  uint64 arbitrumChainSelector = 4_949_039_107_694_359_620;
  uint256 gasLimit = 200_000;
  address gyd = address(0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A);
  address ccipRouterAddress =
    address(0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D);

  GydL1CCIPEscrow v1;
  GydL1CCIPEscrow proxyV1;
  GydL1CCIPEscrow mockedV1;
  GydL1CCIPEscrow mockedProxyV1;
  GydL1EscrowV2Mock v2;
  GydL1EscrowV2Mock proxyV2;
  RouterMock router;

  function setUp() public {
    vm.createSelectFork(ETH_RPC_URL, 19_668_921);

    v1 = new GydL1CCIPEscrow();
    bytes memory v1Data = abi.encodeWithSelector(
      GydL1CCIPEscrow.initialize.selector,
      admin,
      gyd,
      ccipRouterAddress,
      new GydL1CCIPEscrow.ChainData[](0)
    );
    UUPSProxy proxy = new UUPSProxy(address(v1), v1Data);
    proxyV1 = GydL1CCIPEscrow(address(proxy));
    vm.prank(admin);
    proxyV1.addChain(arbitrumChainSelector, gyd, gasLimit);

    mockedV1 = new GydL1CCIPEscrow();
    router = new RouterMock();
    bytes memory mockedV1Data = abi.encodeWithSelector(
      GydL1CCIPEscrow.initialize.selector,
      admin,
      gyd,
      address(router),
      new GydL1CCIPEscrow.ChainData[](0)
    );
    UUPSProxy mockedProxy = new UUPSProxy(address(v1), mockedV1Data);
    mockedProxyV1 = GydL1CCIPEscrow(address(mockedProxy));
    vm.prank(admin);
    mockedProxyV1.addChain(arbitrumChainSelector, gyd, gasLimit);
    v2 = new GydL1EscrowV2Mock();
    proxyV2 = GydL1EscrowV2Mock(address(proxyV1));

    // Donate small amount of GYD to GydL1CCIPEscrow
    uint256 donateAmount = 0.01 ether;
    vm.store(
      gyd, keccak256(abi.encode(address(proxyV1), 2)), bytes32(donateAmount)
    );
    vm.store(
      gyd,
      keccak256(abi.encode(address(mockedProxyV1), 2)),
      bytes32(donateAmount)
    );
  }

  // ==========================================================================
  // == Upgradeability ========================================================
  // ==========================================================================

  /// @notice Upgrade as admin; make sure it works as expected
  function testUpgradeAsAdmin() public {
    // Pre-upgrade check
    assertEq(proxyV1.totalBridgedGYD(0), 0);
    vm.expectRevert("ERC20: insufficient allowance");
    proxyV1.bridgeToken(0, alice, 1 ether);

    vm.startPrank(admin);
    proxyV1.upgradeToAndCall(address(v2), "");
    proxyV2.bridgeToken(0, alice, 1 ether);
    assertEq(proxyV1.totalBridgedGYD(0), 2 ether);
  }

  /// @notice Upgrade as non-admin; make sure it reverted
  function testUpgradeAsNonAdmin() public {
    vm.startPrank(alice);
    vm.expectRevert(
      abi.encodeWithSelector(
        IAccessControl.AccessControlUnauthorizedAccount.selector, alice, 0x00
      )
    );
    proxyV1.upgradeToAndCall(address(v2), "");
  }

  // ==========================================================================
  // == bridge ================================================================
  // ==========================================================================

  /// @notice Make sure GydL1CCIPEscrow submit correct message to the bridge
  function testBridgeWithMockedBridge(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    vm.startPrank(alice);
    uint256 fees =
      mockedProxyV1.getFee(arbitrumChainSelector, alice, bridgeAmount);
    deal(alice, fees);
    deal(gyd, alice, bridgeAmount);
    IERC20(gyd).safeIncreaseAllowance(address(mockedProxyV1), bridgeAmount);

    mockedProxyV1.bridgeToken{value: fees}(
      arbitrumChainSelector, alice, bridgeAmount
    );
    vm.stopPrank();

    assertEq(IERC20(gyd).balanceOf(alice), 0);
    assertEq(IERC20(gyd).balanceOf(address(mockedProxyV1)), bridgeAmount);
    assertEq(
      mockedProxyV1.totalBridgedGYD(arbitrumChainSelector), bridgeAmount
    );

    assertEq(router.destinationChainSelector(), arbitrumChainSelector);
    assertEq(router.destAddress(), gyd);
    assertEq(router.recipient(), alice);
    assertEq(router.amount(), bridgeAmount);
    assertEq(router.gasLimit(), gasLimit);
  }

  /// @notice Make sure GydL1CCIPEscrow can interact with the router
  function testBridgeWithRealBridge(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    vm.startPrank(alice);
    uint256 fees =
      mockedProxyV1.getFee(arbitrumChainSelector, alice, bridgeAmount);
    deal(alice, fees);
    deal(gyd, alice, bridgeAmount);
    IERC20(gyd).safeIncreaseAllowance(address(proxyV1), bridgeAmount);
    proxyV1.bridgeToken{value: fees}(
      arbitrumChainSelector, alice, bridgeAmount
    );
    vm.stopPrank();

    assertEq(proxyV1.totalBridgedGYD(arbitrumChainSelector), bridgeAmount);
    assertEq(IERC20(gyd).balanceOf(alice), 0);
    assertEq(IERC20(gyd).balanceOf(address(proxyV1)), bridgeAmount);
  }

  //
  // ==========================================================================
  // == onMessageReceived
  // =====================================================
  //
  // ==========================================================================

  /// @notice Make sure to revert if message is invalid
  function testOnMessageReceivedInvalidMessage(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    vm.startPrank(alice);
    uint256 fees = proxyV1.getFee(arbitrumChainSelector, alice, bridgeAmount);
    deal(alice, fees);
    deal(gyd, alice, bridgeAmount);
    IERC20(gyd).safeIncreaseAllowance(address(proxyV1), bridgeAmount);
    proxyV1.bridgeToken{value: fees}(
      arbitrumChainSelector, alice, bridgeAmount
    );
    vm.stopPrank();

    address routerAddress = address(proxyV1.router());
    (address originAddress,) = proxyV1.chainsMetadata(arbitrumChainSelector);
    uint64 chainSelector = arbitrumChainSelector;
    bytes memory data = abi.encode(bob, 1 ether, "");

    // Invalid caller
    vm.startPrank(bob);
    vm.expectRevert(
      abi.encodeWithSelector(
        CCIPReceiverUpgradeable.InvalidRouter.selector, bob
      )
    );
    proxyV1.ccipReceive(_receivedMessage(chainSelector, originAddress, data));
    vm.stopPrank();

    // Valid caller; invalid origin address
    vm.startPrank(routerAddress);
    vm.expectRevert(abi.encodeWithSelector(IGydBridge.MessageInvalid.selector));
    proxyV1.ccipReceive(_receivedMessage(chainSelector, address(0), data));
    vm.stopPrank();

    // Valid caller; invalid origin network
    vm.startPrank(routerAddress);
    vm.expectRevert(
      abi.encodeWithSelector(IGydBridge.ChainNotSupported.selector, 0)
    );
    proxyV1.ccipReceive(_receivedMessage(0, originAddress, data));
    vm.stopPrank();

    // Valid caller; invalid metadata
    vm.startPrank(routerAddress);
    vm.expectRevert();
    proxyV1.ccipReceive(_receivedMessage(chainSelector, originAddress, ""));
    vm.stopPrank();
  }

  /// @notice Make sure user can claim the GYD
  function testOnMessageReceivedValidMessage(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    vm.startPrank(alice);
    uint256 fees = proxyV1.getFee(arbitrumChainSelector, alice, bridgeAmount);
    deal(alice, fees);
    deal(gyd, alice, bridgeAmount);
    IERC20(gyd).safeIncreaseAllowance(address(proxyV1), bridgeAmount);
    proxyV1.bridgeToken{value: fees}(arbitrumChainSelector, bob, bridgeAmount);
    vm.stopPrank();

    address routerAddress = address(proxyV1.router());
    (address originAddress,) = proxyV1.chainsMetadata(arbitrumChainSelector);
    uint64 chainSelector = arbitrumChainSelector;
    bytes memory messageData = abi.encode(bob, bridgeAmount, "");

    vm.startPrank(routerAddress);
    proxyV1.ccipReceive(
      _receivedMessage(chainSelector, originAddress, messageData)
    );
    vm.stopPrank();

    assertEq(IERC20(gyd).balanceOf(bob), bridgeAmount);
    assertEq(proxyV1.totalBridgedGYD(arbitrumChainSelector), 0);
  }

  function testUpdateGasLimit() public {
    uint256 newGasLimit = 100_000;

    vm.prank(admin);
    proxyV1.updateGasLimit(arbitrumChainSelector, newGasLimit);

    (, uint256 gasLimit_) = proxyV1.chainsMetadata(arbitrumChainSelector);
    assertEq(gasLimit_, newGasLimit);
  }

  function _receivedMessage(
    uint64 chainSelector,
    address senderContract,
    bytes memory data
  ) internal pure returns (Client.Any2EVMMessage memory) {
    return Client.Any2EVMMessage({
      messageId: 0,
      sourceChainSelector: chainSelector,
      sender: abi.encode(senderContract),
      data: data,
      destTokenAmounts: new Client.EVMTokenAmount[](0)
    });
  }
}
