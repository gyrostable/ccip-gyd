## CCIP GYD Bridge

The code is based on the [zkEVM DAI bridge](https://github.com/pyk/zkevm-dai)

### Introduction

Bridged GYD implementation consists of two smart contracts:

1. **GydL1Escrow**: This contract is deployed on Ethereum mainnet.
2. **L2Gyd**: This contract is deployed on L2s.

The user can do the following:

1. Bridge GYD from Ethereum mainnet to an L2 via `GydL1Escrow` contract.
2. Bridge GYD from an L2 to Ethereum mainnet via `L2Gyd` contract.

## Get started

### Requirements

This repository uses foundry. You can install foundry via
[foundryup](https://book.getfoundry.sh/getting-started/installation).

### Setup

Clone the repository:

```sh
git clone git@github.com:gyrostable/ccip-gyd.git
cd ccip-gyd/
```

Install the dependencies:

```sh
forge install
```

### Tests

Create `.env` with the following contents:

```
ETH_RPC_URL=""
ARBITRUM_RPC_URL="https://arb1.arbitrum.io/rpc"
ETHERSCAN_API_KEY=""
```

Use the following command to run the test:

```sh
forge test
```

> **Note**
> You can set `ETHERSCAN_API_KEY` to helps you debug the call trace.

## Deployment

Deployment scripts are located in the [`script`](./script/) directory.

## Contract addresses

| Smart contract       | Network       | Address                                                                                                                        |
| -------------------- | ------------- | ------------------------------------------------------------------------------------------------------------------------------ |
| GYD                  | Mainnet       | [0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A](https://etherscan.io/address/0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A)          |
| CCIP router | Mainnet       | [0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D](https://etherscan.io/address/0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D)          |
|                      | Arbitrum | [0x141fa059441E0ca23ce184B6A78bafD2A517DdE8](https://arbiscan.io/address/0x141fa059441E0ca23ce184B6A78bafD2A517DdE8) |
| GydL1CCIPEscrow             | Mainnet       | [0xa1886c8d748DeB3774225593a70c79454B1DA8a6](https://etherscan.io/address/0xa1886c8d748DeB3774225593a70c79454B1DA8a6)          |
| L2Gyd                | Arbitrum | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://arbiscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8) |

