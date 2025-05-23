## CCIP GYD/GYFI Bridge

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

| Smart contract      | Network       | Address                                                                                                                |
| ------------------- | ------------- | ---------------------------------------------------------------------------------------------------------------------- |
| GYD                 | Mainnet       | [0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A](https://etherscan.io/address/0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A)  |
| GYFI                | Mainnet       | [0x70c4430f9d98B4184A4ef3E44CE10c320a8B7383](https://etherscan.io/address/0x70c4430f9d98B4184A4ef3E44CE10c320a8B7383)  |
| CCIP router         | Mainnet       | [0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D](https://etherscan.io/address/0x80226fc0Ee2b096224EeAc085Bb9a8cba1146f7D)  |
|                     | Arbitrum      | [0x141fa059441E0ca23ce184B6A78bafD2A517DdE8](https://arbiscan.io/address/0x141fa059441E0ca23ce184B6A78bafD2A517DdE8)   |
| GydL1CCIPEscrow     | Mainnet       | [0xa1886c8d748DeB3774225593a70c79454B1DA8a6](https://etherscan.io/address/0xa1886c8d748DeB3774225593a70c79454B1DA8a6)  |
| L2Gyd               | Arbitrum      | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://arbiscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| L2Gyd               | Optimism      | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://optimistic.etherscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| L2Gyd               | Avalanche     | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://snowtrace.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| L2Gyd               | Polygon       | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://polygonscan.com/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| L2Gyd               | Base          | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://basescan.org/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| L2Gyd               | Gnosis        | [0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8](https://gnosisscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8)   |
| GyfiL1CCIPEscrow    | Mainnet       | [0x2154F6242F2F7B82A88E7C912dc0aA644F557061](https://etherscan.io/address/0x2154F6242F2F7B82A88E7C912dc0aA644F557061)  |
| L2Gyfi              | Arbitrum      | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://arbiscan.io/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Base          | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://basescan.org/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Avalanche     | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://snowtrace.io/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Optimism      | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://optimistic.etherscan.io/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Polygon       | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://polygonscan.com/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Sonic         | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://sonicscan.org/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Sei           | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://seitrace.com/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | Gnosis        | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://gnosisscan.io/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |
| L2Gyfi              | zkEVM         | [0xc63529297dE076eB15fcbE873AE9136E446cFbB9](https://zkevm.polygonscan.com/address/0xc63529297dE076eB15fcbE873AE9136E446cFbB9)   |



# How to bridge GYD manually: Ethereum ↔ Arbitrum

The GYD bridge uses Chainlink CCIP in the background but there is currently no UI (and the CCIP UI has not integrated GYD, either). So any bridging has to be done manually / through Etherscan.

The bridge works by a standard lock-and-mint mechanism and communicates with Arbitrum through CCIP message passing. Fees for the message passing have to be paid in ETH when the bridging is initiated. The bridge contract helps compute the fees.

This manual applies to the Ethereum ↔ Arbitrum bridge. The Ethereum ↔ zkEVM bridge is different in some details and a UI for that bridge is available from Polygon.

## CCIP Chain Selectors

To indicate the target L2 chain, CCIP does not use chain IDs but instead its own system of “chain selectors,” which are as follows. The chain selector has to be provided to GydL1CCIPEscrow when bridging. See here for details: https://github.com/smartcontractkit/chain-selectors/blob/main/selectors.yml 


| Target Chain | Selector             |
|--------------|----------------------|
| mainnet      | 5009297550715157269  |
| arbitrum     | 4949039107694359620  |
| optimism     | 3734403246176062136  |
| avalanche    | 6433500567565415381  |
| polygon      | 4051577828743386545  |
| base         | 15971525489660198786 |
| gnosis       | 465200170687744372   |

## Bridging from Ethereum to Arbitrum

Assume you want to bridge some given amount AMOUNT from Mainnet to Arbitrum. Let AMOUNT be the  decimal-scaled value (in 18 decimals), e.g., 1000000000000000000 for 1.0 GYD. Let RECIPIENT be the recipient address on Arbitrum.

1. On Mainnet, on [GYD](https://etherscan.io/address/0xe07F9D810a48ab5c3c914BA3cA53AF14E4491e8A), approve AMOUNT to GydL1CCIPEscrow:
    ```
    GYD.approve(0xa1886c8d748DeB3774225593a70c79454B1DA8a6, AMOUNT)
    ```
2. On Mainnet, on [GydL1CCIPEscrow](https://etherscan.io/address/0xa1886c8d748DeB3774225593a70c79454B1DA8a6), calculate the fees for bridging (view method).
    ```
    GydL1CCIPEscrow.getFee(4949039107694359620, RECIPIENT, AMOUNT)
    ```
    This returns a Wei value of ETH.
    Call the result FEE.
3. On Mainnet on [GydL1CCIPEscrow](https://etherscan.io/address/0xa1886c8d748DeB3774225593a70c79454B1DA8a6), initiate the bridging operation:
    ```
    GydL1CCIPEscrow.bridgeToken(4949039107694359620, RECIPIENT, AMOUNT) 
    ```
    with payable amount = FEE
    In Etherscan, payable amount shows up as the first “parameter” also called “bridgeToken” and has to be specified in ETH, i.e., FEE / 1e18.

FEE should be on the order of $0.50 equivalent.

Now you have to wait about 20 minutes for CCIP to process the transaction. You can pop your Ethereum transaction hash into the [CCIP Explorer](https://ccip.chain.link/) to see the progress of the bridging operation. It’s normal that this shows “Tokens and Amounts” = None because the bridge uses a message rather than CCIP’s built-in token bridging.

When the transaction is processed, the tokens appear at RECIPIENT on Arbitrum.

Note that there are also variants of the above functions with a data parameter. This is for when RECIPIENT is a smart contract and we want to call a method there (not needed here).

## Bridging from Arbitrum to Ethereum

To bridge from Arbitrum back down to Ethereum, we do a very similar thing, this time calling into L2Gyd on Arbitrum. We don’t need to pass a chain selector this time because we always bridge to Ethereum. Like before, let AMOUNT be the decimal-scaled amount to bridge and RECIPIENT the recipient address on Ethereum. We also don’t need to approve because the token contract and the bridging entry point are the same.

1. On Arbitrum, on [L2Gyd](https://arbiscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8), calculate the fees for bridging (view method).
    ```
    L2Gyd.getFee(RECIPIENT, AMOUNT)
    ```
    This returns a Wei value in ETH.
    Call the result FEE.
2. On Arbitrum, on [L2Gyd](https://arbiscan.io/address/0xCA5d8F8a8d49439357d3CF46Ca2e720702F132b8), initiate the bridging operation:
    ```
    L2Gyd.bridgeToken(RECIPIENT, AMOUNT) 
    ```
    with payable amount = FEE
    
    For Arbiscan, the same as above applies for entering the FEE.

FEE can vary is currently around $5 equivalent.

This direction also takes around 20 minutes. Just like for the other direction, you can put your Arbitrum transaction hash into the CCIP explorer to see the progress. The tokens then appear at RECIPIENT on Ethereum. Like for the other direction, there are also variants of the functions with a data attribute, but this is not needed here.
