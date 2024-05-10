// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {L2Gyd} from "src/L2Gyd.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

/**
 * @title DeployL2Gyd
 * @notice Script to deploy L2Gyd
 */
contract DeployL2Gyd is Script {
  // https://arbiscan.io/address/0x8bc920001949589258557412A32F8d297A74F244
  address deployer = 0x8bc920001949589258557412A32F8d297A74F244;

  // Multisig Owned by Gyroscope Team
  // https://app.safe.global/home?safe=arb:0x0a2B93a5e0281557428cbD7eD75aa76DADD6C6Ab
  address owner = 0x0a2B93a5e0281557428cbD7eD75aa76DADD6C6Ab;

  // CCIP router (Arbitrum)
  // https://arbiscan.io/address/0x141fa059441E0ca23ce184B6A78bafD2A517DdE8
  address ccipRouter = 0x141fa059441E0ca23ce184B6A78bafD2A517DdE8;
  uint64 mainnetChainSelector = 5_009_297_550_715_157_269;

  uint256 bridgeGasLimit = 200_000; // max 200k gas to complete the bridging

  address l1Address;

  // CREATE3 Factory
  ICREATE3Factory factory =
    ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1);

  function setUp() public {
    l1Address =
      factory.getDeployed(deployer, keccak256(bytes("GydL1CCIPEscrow")));
  }

  function run() public returns (address proxy) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);

    L2Gyd l2Gyd = new L2Gyd();
    bytes memory data = abi.encodeWithSelector(
      L2Gyd.initialize.selector,
      owner,
      ccipRouter,
      l1Address,
      mainnetChainSelector,
      bridgeGasLimit
    );
    bytes32 salt = keccak256(bytes("L2Gyd"));
    bytes memory creationCode = abi.encodePacked(
      type(UUPSProxy).creationCode, abi.encode(address(l2Gyd), data)
    );
    proxy = factory.deploy(salt, creationCode);

    vm.stopBroadcast();
  }
}
