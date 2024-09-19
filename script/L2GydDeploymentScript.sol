// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {L2Gyd} from "src/L2Gyd.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

contract L2GydDeploymentScript is Script {
  bytes32 public constant L2_GYD_SALT = "L2Gyd";

  // https://etherscan.io/address/0x8bc920001949589258557412A32F8d297A74F244
  address deployer = 0x8bc920001949589258557412A32F8d297A74F244;

  // L2 governance
  // this is the same address for all networks
  // https://arbiscan.io/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  // https://optimistic.etherscan.io/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  // https://polygonscan.com/address/0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568
  address owner = 0xd62bb3c3D6C7BD5C6bA64aA4D7BF05aE6AD10568;

  // CREATE3 Factory
  ICREATE3Factory factory =
    ICREATE3Factory(0x93FEC2C00BfE902F733B57c5a6CeeD7CD1384AE1);

  function _deploy(address ccipRouter) public returns (address proxy) {
    uint256 deployerPrivateKey = uint256(vm.envBytes32("PRIVATE_KEY"));

    vm.startBroadcast(deployerPrivateKey);

    L2Gyd l2Gyd = new L2Gyd();
    bytes memory data =
      abi.encodeWithSelector(L2Gyd.initialize.selector, owner, ccipRouter);
    bytes32 salt = keccak256(bytes("L2Gyd"));
    bytes memory creationCode = abi.encodePacked(
      type(UUPSProxy).creationCode, abi.encode(address(l2Gyd), data)
    );
    proxy = factory.deploy(salt, creationCode);

    vm.stopBroadcast();
  }
}
