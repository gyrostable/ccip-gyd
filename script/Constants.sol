// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library CCIPSelectors {
  // https://docs.chain.link/ccip/directory/mainnet/chain/mainnet
  uint64 internal constant MAINNET = 5_009_297_550_715_157_269;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-arbitrum-1
  uint64 internal constant ARBITRUM = 4_949_039_107_694_359_620;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-base-1
  uint64 internal constant BASE = 15_971_525_489_660_198_786;
}
