# ilrta [![GitHub Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/kyscott18/ilrta/actions
[gha-badge]: https://github.com/kyscott18/ilrta/actions/workflows/main.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

**ilrta** is a collection of smart contracts focused on signature-based token transfers. This currently consists of:

- `SuperSignature.sol`: A next-generation signature authentication scheme based around sign + verify once, use everywhere architecture.
- `Permit3.sol`: Next version of permit2 with SuperSignature, EIP 6492, and multiple token standard support.
- `ILRTA.sol`: Token standard for token standards. Easily tokenize any data adn inherit a composable signature transfer scheme.

There are also some shared files and examples implementations.

## SuperSignature

### Abstract

Inspired by witness data in permit2, SuperSignature allows for arbitrary to be signed in a batch, and only verified on chain once. This is primarily useful when trying to save gas, by cutting down on calldata size and on-chain computation. It generally works by signing and verifying an array of typed datahashed, storing the root of these hashes, and calling back later in the transaction to validate an individual typed datahash.

### Features

- Standardized api for batched signature verification
- Highly scalable gas savings for meta transactions

## Permit3

### Features

- Allows for a highly composable SuperSignature transfer scheme.
- Supports signatures for undeployed smart contract wallets (EIP 6492)
- Implementation for ERC20, ERC721, and ERC1155

## ILRTA

### Abstract

This protocol is adapted around two main ideas: token standards at their core just represent ownership over arbitrary data, and the approve flow used by almost all token standards is suboptimal.

### Features

- Easiest way to create a token type for one-off contracts
- Consistent events across all inheriting contracts
- Signature based transfers with EIP712 typed data
- Contract based signatures included by default
- Full test suite running with Foundry

### Example Implementations

To show backwards compatibility, many popular token standards have been implementing while also conforming to the ilrta standard.

- [ERC20](https://github.com/kyscott18/ilrta/blob/main/src/examples/ERC20.sol)
- [WETH](https://github.com/kyscott18/ilrta/blob/main/src/examples/WETH.sol)

As well as some more examples, such as:

- [FungibleToken](https://github.com/kyscott18/ilrta/blob/main/src/examples/FungibleToken.sol)
- [SemiFungibleToken](https://github.com/kyscott18/ilrta/blob/main/src/examples/SemiFungibleToken.sol)

## Install

You will need a copy of [Foundry](https://getfoundry.sh/) installed before proceeding.

### Setup

```sh
forge install
pnpm install
```

### Build

```sh
forge build
```

### Lint

```sh
pnpm lint
```

### Format

```sh
pnpm format
```

### Test

```sh
forge test
```

### Gas Snapshot

```sh
forge snapshot
```

## Potential Improvments

- Pass in the address of the super signature contract
- Anything to make super signatures show up in a more readable way in wallets

## Acknowledgements

- **Uniswap's permit2** for their signature verification implementation and pushing the boundaries of what I thought was possible
- **Uniswap's v3-core** for showing the need of an extensible standard for creating small token types
- **Noah Zinsmeister and Sara Reynolds** for personally taking the time to talk through some of these ideas
- **Solmate** for an incredibly clean eip2612 and erc20 implementation to base off of
- [**This Twitter thread**](https://twitter.com/pcaversaccio/status/1645084293989822466?s=20) for discussion on the shortcomings of current standards
