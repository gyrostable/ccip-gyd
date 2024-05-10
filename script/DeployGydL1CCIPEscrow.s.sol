// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {GydL1CCIPEscrow} from "src/GydL1CCIPEscrow.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

/**
 * @title DeployGydL1Escrow
 * @notice Script to deploy GydL1CCIPEscrow
 */
contract DeployGydL1CCIPEscrow is Script {
  // https://etherscan.io/address/0x8bc920001949589258557412A32F8d297A74F244
  address deployer = 0x8bc920001949589258557412A32F8d297A74F244;

  // Gyroscope governance contract
  // https://etherscan.io/address/0x78EcF97572c3890eD02221A611014F30219f6219
  address admin = 0x78EcF97572c3890eD02221A611014F30219f6219;

  // GYD
  // https://etherscan.io/address/0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A
  address gyd = 0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A;

  // CCIP router
  // https://etherscan.io/address/0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D
  address ccipRouter = 0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D;

  // L2 address
  address l2Address;

  // Arbitrum chain selector
  // https://docs.chain.link/ccip/supported-networks/v1_2_0/mainnet#arbitrum-mainnet
  uint64 arbitrumChainSelector = 4_949_039_107_694_359_620;

  uint256 gasLimit = 200_000; // max 200k gas to complete the bridging

  // CREATE3 Factory
  ICREATE3Factory factory =
    ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1);

  function setUp() public {
    l2Address = factory.getDeployed(deployer, keccak256(bytes("L2Gyd")));
  }

  function run() public returns (address proxy) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);

    GydL1CCIPEscrow gydL1Escrow = new GydL1CCIPEscrow();

    // Only support Arbitrum chain on deployment
    GydL1CCIPEscrow.ChainData[] memory chains =
      new GydL1CCIPEscrow.ChainData[](1);
    chains[0] = GydL1CCIPEscrow.ChainData({
      chainSelector: arbitrumChainSelector,
      metadata: GydL1CCIPEscrow.ChainMetadata({
        gydAddress: l2Address,
        gasLimit: gasLimit
      })
    });

    bytes memory data = abi.encodeWithSelector(
      GydL1CCIPEscrow.initialize.selector, admin, gyd, ccipRouter, chains
    );
    bytes32 salt = keccak256(bytes("GydL1CCIPEscrow"));
    bytes memory creationCode = abi.encodePacked(
      type(UUPSProxy).creationCode, abi.encode(address(gydL1Escrow), data)
    );
    proxy = factory.deploy(salt, creationCode);

    vm.stopBroadcast();
  }
}
