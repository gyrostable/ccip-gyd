// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {OwnableUpgradeable} from "upgradeable/access/OwnableUpgradeable.sol";

import {L2Gyd} from "src/L2Gyd.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {RouterMock} from "./RouterMock.sol";

import {Client} from "ccip/libraries/Client.sol";
import {CCIPReceiverUpgradeable} from "../src/CCIPReceiverUpgradeable.sol";

/**
 * @title L2GydV2Mock
 * @notice Mock contract to test upgradeability of L2Gyd smart contract
 */
contract L2GydV2Mock is L2Gyd {
  uint256 public some;

  /// @dev Update ccipReceive implementation for testing purpose
  function ccipReceive(Client.Any2EVMMessage calldata)
    external
    virtual
    override
  {
    some = 42;
  }

  /// @dev Add new function for testing purpose
  function getValue() public view returns (uint256 b) {
    b = some;
  }
}

/**
 * @title L2GydTest
 * @notice Unit tests for L2Gyd
 */
contract L2GydTest is Test {
  string ARBITRUM_RPC_URL = vm.envString("ARBITRUM_RPC_URL");

  address owner = makeAddr("owner");
  address alice = makeAddr("alice");
  address bob = makeAddr("bob");

  address routerAddress = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;
  address destAddress = makeAddr("L1CCIPEscrow");
  uint64 mainnetChainSelector = 3_734_403_246_176_062_136;
  uint256 gasLimit = 200_000;

  L2Gyd v1;
  L2Gyd proxyV1;
  L2GydV2Mock v2;
  L2GydV2Mock proxyV2;
  L2Gyd mockedV1;
  L2Gyd mockedProxyV1;
  RouterMock router;

  function setUp() public {
    vm.createSelectFork(ARBITRUM_RPC_URL, 209_934_488);

    v1 = new L2Gyd();
    bytes memory v1Data = abi.encodeWithSelector(
      L2Gyd.initialize.selector,
      owner,
      routerAddress,
      destAddress,
      mainnetChainSelector,
      gasLimit
    );
    UUPSProxy proxy = new UUPSProxy(address(v1), v1Data);
    proxyV1 = L2Gyd(address(proxy));

    mockedV1 = new L2Gyd();
    router = new RouterMock();
    bytes memory v2Data = abi.encodeWithSelector(
      L2Gyd.initialize.selector,
      owner,
      address(router),
      destAddress,
      mainnetChainSelector,
      gasLimit
    );
    UUPSProxy mockedProxy = new UUPSProxy(address(v1), v2Data);
    mockedProxyV1 = L2Gyd(address(mockedProxy));

    v2 = new L2GydV2Mock();
    proxyV2 = L2GydV2Mock(address(proxyV1));
  }

  //
  // ==========================================================================
  // == Upgradeability
  // ========================================================
  //
  // ==========================================================================

  /// @notice Upgrade as owner; make sure it works as expected
  function testUpgradeAsOwner() public {
    // Pre-upgrade check
    assertEq(proxyV1.owner(), owner);

    vm.startPrank(owner);
    proxyV1.upgradeToAndCall(address(v2), "");
    vm.stopPrank();

    // Post-upgrade check
    // Make sure new function exists
    proxyV2.ccipReceive(_receivedMessage(0, address(0), ""));
    assertEq(proxyV2.getValue(), 42);
  }

  /// @notice Upgrade as non-owner; make sure it reverted
  function testUpgradeAsNonOwner() public {
    vm.startPrank(alice);
    vm.expectRevert(
      abi.encodeWithSelector(
        OwnableUpgradeable.OwnableUnauthorizedAccount.selector, alice
      )
    );
    proxyV1.upgradeToAndCall(address(v2), "");
  }

  //
  // ==========================================================================
  // == router
  // ================================================================
  //
  // ==========================================================================

  /// @notice Make sure L2Gyd submit correct message to the router
  function testBridgeWithMockedBridge(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    // Mint test NativeGYD
    vm.startPrank(address(router));
    bytes memory data = abi.encode(alice, bridgeAmount, "");
    mockedProxyV1.ccipReceive(
      _receivedMessage(mainnetChainSelector, destAddress, data)
    );
    vm.stopPrank();

    vm.startPrank(alice);
    uint256 fees = mockedProxyV1.getFee(alice, bridgeAmount);
    deal(alice, fees);
    mockedProxyV1.bridgeToken{value: fees}(alice, bridgeAmount);
    vm.stopPrank();

    assertEq(mockedProxyV1.balanceOf(alice), 0);
    assertEq(mockedProxyV1.totalSupply(), 0);

    assertEq(router.destinationChainSelector(), mainnetChainSelector);
    assertEq(router.destAddress(), destAddress);
    assertEq(router.recipient(), alice);
    assertEq(router.amount(), bridgeAmount);
    assertEq(router.gasLimit(), gasLimit);
  }

  /// @notice Make sure L2Gyd can interact with the router
  function testBridgeWithRealBridge(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    // Mint test NativeGYD
    vm.startPrank(routerAddress);
    bytes memory data = abi.encode(alice, bridgeAmount, "");
    proxyV1.ccipReceive(
      _receivedMessage(mainnetChainSelector, destAddress, data)
    );
    vm.stopPrank();

    vm.startPrank(alice);
    uint256 fees = proxyV1.getFee(alice, bridgeAmount);
    deal(alice, fees);
    proxyV1.bridgeToken{value: fees}(alice, bridgeAmount);
    vm.stopPrank();

    assertEq(proxyV1.balanceOf(alice), 0);
    assertEq(proxyV1.totalSupply(), 0);
  }

  //
  //
  // ==========================================================================
  // == onMessageReceived
  // =====================================================
  //
  //
  // ==========================================================================

  /// @notice Make sure to revert if message is invalid
  function testOnMessageReceivedInvalidMessage(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    // Mint test NativeGYD
    vm.startPrank(routerAddress);
    bytes memory data = abi.encode(alice, bridgeAmount, "");
    proxyV1.ccipReceive(
      _receivedMessage(mainnetChainSelector, destAddress, data)
    );
    vm.stopPrank();

    vm.startPrank(alice);
    uint256 fees = proxyV1.getFee(alice, bridgeAmount);
    deal(alice, fees);
    proxyV1.bridgeToken{value: fees}(alice, bridgeAmount);
    vm.stopPrank();

    address currentRouterAddress = address(proxyV1.router());
    address originAddress = proxyV1.destAddress();
    uint64 chainSelector = proxyV1.mainnetChainSelector();
    bytes memory metadata = abi.encode(bob, 1 ether, "");

    // Invalid caller
    vm.startPrank(bob);
    vm.expectRevert(
      abi.encodeWithSelector(
        CCIPReceiverUpgradeable.InvalidRouter.selector, bob
      )
    );
    proxyV1.ccipReceive(
      _receivedMessage(chainSelector, originAddress, metadata)
    );
    vm.stopPrank();

    // Valid caller; invalid origin address
    vm.startPrank(currentRouterAddress);
    vm.expectRevert(abi.encodeWithSelector(L2Gyd.MessageInvalid.selector));
    proxyV1.ccipReceive(_receivedMessage(chainSelector, address(0), metadata));
    vm.stopPrank();

    // Valid caller; invalid origin network
    vm.startPrank(currentRouterAddress);
    vm.expectRevert(abi.encodeWithSelector(L2Gyd.MessageInvalid.selector));
    proxyV1.ccipReceive(_receivedMessage(1, originAddress, metadata));
    vm.stopPrank();

    // Valid caller; invalid metadata
    vm.startPrank(currentRouterAddress);
    vm.expectRevert();
    proxyV1.ccipReceive(_receivedMessage(chainSelector, originAddress, ""));
    vm.stopPrank();
  }

  /// @notice Make sure user can claim the GYD
  function testOnMessageReceivedValidMessage(uint256 bridgeAmount) public {
    vm.assume(bridgeAmount > 1 ether);
    vm.assume(bridgeAmount < 1_000_000_000 ether);

    // Mint test NativeGYD
    vm.startPrank(routerAddress);
    bytes memory data = abi.encode(alice, bridgeAmount, "");
    proxyV1.ccipReceive(
      _receivedMessage(mainnetChainSelector, destAddress, data)
    );
    vm.stopPrank();

    vm.startPrank(alice);
    uint256 fees = proxyV1.getFee(alice, bridgeAmount);
    deal(alice, fees);
    proxyV1.bridgeToken{value: fees}(bob, bridgeAmount);
    vm.stopPrank();

    address currentRouterAddress = address(proxyV1.router());
    address originAddress = proxyV1.destAddress();
    uint64 chainSelector = proxyV1.mainnetChainSelector();
    bytes memory messageData = abi.encode(bob, bridgeAmount, "");

    vm.startPrank(currentRouterAddress);
    proxyV1.ccipReceive(
      _receivedMessage(chainSelector, originAddress, messageData)
    );
    vm.stopPrank();

    assertEq(proxyV1.balanceOf(bob), bridgeAmount);
    assertEq(proxyV1.totalSupply(), bridgeAmount);
  }

  function testUpdateGasLimit() public {
    uint256 newGasLimit = 100_000;

    vm.prank(owner);
    proxyV2.updateGasLimit(newGasLimit);

    assertEq(proxyV2.bridgeGasLimit(), newGasLimit);
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
