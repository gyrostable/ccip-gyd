// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

library CCIPSelectors {
  // https://docs.chain.link/ccip/directory/mainnet/chain/mainnet
  uint64 internal constant MAINNET = 5_009_297_550_715_157_269;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-arbitrum-1
  uint64 internal constant ARBITRUM = 4_949_039_107_694_359_620;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-base-1
  uint64 internal constant BASE = 15_971_525_489_660_198_786;

  // https://docs.chain.link/ccip/directory/mainnet/chain/matic-mainnet
  uint64 internal constant POLYGON = 4_051_577_828_743_386_545;

  // https://docs.chain.link/ccip/directory/mainnet/chain/xdai-mainnet
  uint64 internal constant GNOSIS = 465_200_170_687_744_372;

  // https://docs.chain.link/ccip/directory/mainnet/chain/avalanche-mainnet
  uint64 internal constant AVALANCHE = 6_433_500_567_565_415_381;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-optimism-1
  uint64 internal constant OPTIMISM = 3_734_403_246_176_062_136;

  // https://docs.chain.link/ccip/directory/mainnet/chain/sei-mainnet
  uint64 internal constant SEI = 9_027_416_829_622_342_829;

  // https://docs.chain.link/ccip/directory/mainnet/chain/sonic-mainnet
  uint64 internal constant SONIC = 1_673_871_237_479_749_969;

  // https://docs.chain.link/ccip/directory/mainnet/chain/ethereum-mainnet-polygon-zkevm-1
  uint64 internal constant ZKEVM = 4_348_158_687_435_793_198;
}
