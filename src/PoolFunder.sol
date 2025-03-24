// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.24;

import {Address} from "oz/utils/Address.sol";
import {IERC20} from "oz/token/ERC20/IERC20.sol";

interface BalancerV2Vault {
  enum JoinKind {
    INIT,
    EXACT_TOKENS_IN_FOR_BPT_OUT,
    TOKEN_IN_FOR_EXACT_BPT_OUT,
    ALL_TOKENS_IN_FOR_EXACT_BPT_OUT
  }

  struct JoinPoolRequest {
    address[] assets;
    uint256[] maxAmountsIn;
    bytes userData;
    bool fromInternalBalance;
  }

  function joinPool(
    bytes32 poolId,
    address sender,
    address recipient,
    JoinPoolRequest calldata request
  ) external;

  function getPoolTokens(bytes32 poolId)
    external
    view
    returns (address[] memory, uint256[] memory, uint256);
}

interface Pool {
  function getPoolId() external view returns (bytes32);
}

contract PoolFunder {
  using Address for address;

  BalancerV2Vault public immutable vault;
  address public immutable factory;
  address public immutable gyd;

  constructor(address vault_, address gyd_, address factory_) {
    gyd = gyd_;
    vault = BalancerV2Vault(vault_);
    factory = factory_;
  }

  function fundPool(uint256 gydAmount, bytes calldata creationData) external {
    bytes memory result = factory.functionCall(creationData);
    address pool = abi.decode(result, (address));
    bytes32 poolId = Pool(pool).getPoolId();
    (address[] memory assets,,) = vault.getPoolTokens(poolId);
    uint256[] memory maxAmountsIn = new uint256[](assets.length);

    for (uint256 i = 0; i < assets.length; i++) {
      if (assets[i] == gyd) {
        maxAmountsIn[i] = gydAmount;
        IERC20(gyd).approve(address(vault), gydAmount);
        break;
      }
    }

    bytes memory userData =
      abi.encode(BalancerV2Vault.JoinKind.INIT, maxAmountsIn);
    vault.joinPool(
      poolId,
      address(this),
      address(this),
      BalancerV2Vault.JoinPoolRequest({
        assets: assets,
        maxAmountsIn: maxAmountsIn,
        userData: userData,
        fromInternalBalance: false
      })
    );
  }
}
