// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {L2Gyfi, IGyfiBridge} from "src/L2Gyfi.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

contract L2GyfiDeploymentScript is Script {
  uint256 gasLimit = 500_000; // max 500k gas to complete the bridging

  // https://etherscan.io/address/0xDA5Cfc724039aECD099735F0974ad31cd0aa04df
  address deployer = 0xDA5Cfc724039aECD099735F0974ad31cd0aa04df;

  // L2 governance
  // this is the same address for all networks
  // https://arbiscan.io/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  // https://optimistic.etherscan.io/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  // https://polygonscan.com/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  address owner = 0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568;

  bytes32 salt = keccak256(bytes("L2Gyfi"));

  address public escrowAddress;
  address public l2GyfiAddress;

  // CREATE3 Factory
  ICREATE3Factory factory =
    ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1);

  function setUp() public {
    escrowAddress =
      factory.getDeployed(deployer, keccak256(bytes("GyfiL1CCIPEscrow")));
    l2GyfiAddress = factory.getDeployed(deployer, salt);
  }

  function _deploy(address ccipRouter, IGyfiBridge.ChainData[] memory chains)
    public
    returns (address proxy)
  {
    vm.startBroadcast();

    L2Gyfi l2Gyfi = new L2Gyfi();
    bytes memory data = abi.encodeWithSelector(
      L2Gyfi.initialize.selector, owner, ccipRouter, chains
    );
    bytes memory constructorArgs = abi.encode(address(l2Gyfi), data);
    console.log("constructorArgs");
    console.logBytes(constructorArgs);
    bytes memory creationCode =
      abi.encodePacked(type(UUPSProxy).creationCode, constructorArgs);
    proxy = factory.deploy(salt, creationCode);
    if (proxy != l2GyfiAddress) {
      revert("Wrong address, use gyro foundation deployer");
    }

    vm.stopBroadcast();
  }
}
