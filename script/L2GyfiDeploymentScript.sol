// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "forge-std/Script.sol";

import {L2Gyfi, IGyfiBridge} from "src/L2Gyfi.sol";

import {UUPSProxy} from "./UUPSProxy.sol";
import {ICREATE3Factory} from "./ICREATE3Factory.sol";

contract L2GyfiDeploymentScript is Script {
  // Mainet chain selector
  // https://docs.chain.link/ccip/directory/mainnet/chain/mainnet
  uint64 mainnetChainSelector = 5_009_297_550_715_157_269;

  uint256 gasLimit = 500_000; // max 200k gas to complete the bridging

  // https://etherscan.io/address/0xDA5Cfc724039aECD099735F0974ad31cd0aa04df
  address deployer = 0xDA5Cfc724039aECD099735F0974ad31cd0aa04df;

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
    address escrowAddress =
      factory.getDeployed(deployer, keccak256(bytes("GyfiL1CCIPEscrow")));
    bytes32 salt = keccak256(bytes("L2Gyfi"));
    address expectedAddress = factory.getDeployed(deployer, salt);

    // Only support mainnet on deployment
    IGyfiBridge.ChainData[] memory chains = new IGyfiBridge.ChainData[](1);
    chains[0] = IGyfiBridge.ChainData({
      chainSelector: mainnetChainSelector,
      metadata: IGyfiBridge.ChainMetadata({
        targetAddress: escrowAddress,
        gasLimit: gasLimit
      })
    });

    vm.startBroadcast();

    L2Gyfi l2Gyfi = new L2Gyfi();
    bytes memory data = abi.encodeWithSelector(
      L2Gyfi.initialize.selector, owner, ccipRouter, chains
    );
    bytes memory creationCode = abi.encodePacked(
      type(UUPSProxy).creationCode, abi.encode(address(l2Gyfi), data)
    );
    proxy = factory.deploy(salt, creationCode);
    if (proxy != expectedAddress) {
      revert("Wrong address, use gyro foundation deployer");
    }

    vm.stopBroadcast();
  }
}
