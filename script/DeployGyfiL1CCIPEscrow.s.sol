// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {GyfiL1CCIPEscrow} from "src/GyfiL1CCIPEscrow.sol";
import {IGyfiBridge} from "src/IGyfiBridge.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

/**
 * @title DeployGyfiL1Escrow
 * @notice Script to deploy GyfiL1CCIPEscrow
 */
contract DeployGyfiL1CCIPEscrow is Script {
  // https://etherscan.io/address/0xDA5Cfc724039aECD099735F0974ad31cd0aa04df
  address deployer = 0xDA5Cfc724039aECD099735F0974ad31cd0aa04df;

  // Gyroscope governance contract
  // https://etherscan.io/address/0x78EcF97572c3890eD02221A611014F30219f6219
  address admin = 0x78EcF97572c3890eD02221A611014F30219f6219;

  // GYFI
  // https://etherscan.io/address/0x70c4430f9d98b4184a4ef3e44ce10c320a8b7383
  address gyfi = 0x70c4430f9d98B4184A4ef3E44CE10c320a8B7383;

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
    l2Address = factory.getDeployed(deployer, keccak256(bytes("L2Gyfi")));
  }

  function run() public returns (address proxy) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);

    GyfiL1CCIPEscrow gyfiL1Escrow = new GyfiL1CCIPEscrow();

    // Only support Arbitrum chain on deployment
    GyfiL1CCIPEscrow.ChainData[] memory chains =
      new GyfiL1CCIPEscrow.ChainData[](1);
    chains[0] = IGyfiBridge.ChainData({
      chainSelector: arbitrumChainSelector,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: l2Address,
        gasLimit: gasLimit
      })
    });

    bytes memory data = abi.encodeWithSelector(
      GyfiL1CCIPEscrow.initialize.selector, admin, gyfi, ccipRouter, chains
    );
    bytes32 salt = keccak256(bytes("GyfiL1CCIPEscrow"));
    bytes memory creationCode = abi.encodePacked(
      type(UUPSProxy).creationCode, abi.encode(address(gyfiL1Escrow), data)
    );
    proxy = factory.deploy(salt, creationCode);

    vm.stopBroadcast();
  }
}
