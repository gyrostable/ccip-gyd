// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";

import {GydL1CCIPEscrow} from "../src/GydL1CCIPEscrow.sol";

contract GydL1EscrowUpgradeTest is Test {
  GydL1CCIPEscrow escrow =
    GydL1CCIPEscrow(0xa1886c8d748DeB3774225593a70c79454B1DA8a6);

  function setUp() public {
    vm.createSelectFork(vm.envString("ETH_RPC_URL"), 20_743_048);
  }

  function testUpgrade() external {
    address newImpl = address(new GydL1CCIPEscrow());
    bytes memory data = abi.encodeWithSelector(
      GydL1CCIPEscrow.initializeTotalBridgedGYD.selector
    );

    vm.prank(escrow.owner());
    escrow.upgradeToAndCall(newImpl, data);

    assertGt(escrow.totalBridgedGYD(), 0);
    assertLt(escrow.totalBridgedGYD(), 30_000_000e18);
  }
}
