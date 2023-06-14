# ilrta [![GitHub Actions][gha-badge]][gha] [![Foundry][foundry-badge]][foundry] [![License: MIT][license-badge]][license]

[gha]: https://github.com/kyscott18/ilrta/actions
[gha-badge]: https://github.com/kyscott18/ilrta/actions/workflows/main.yml/badge.svg
[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

**Token standard for token standards.** Easily tokenize any type of data and inherit a composable signature transfer scheme.

## Features

- Easiest way to create a token type for one-off contracts
- Consistent events across all inheriting contracts
- Signature based transfers with EIP712 typed data
- Contract based signatures included by default
- Full test suite running with Foundry

## H

This protocol is adapted around two main ideas: token standards at their core just represent ownership over arbitrary data, and the approve flow used by almost all token standards is suboptimal. Permit2 solved a lot of problems around the approve flow, but for token standards where we are able to start from scratch, there is room for improvemnt.

## Example Implementations

To show backwards compatibility, many popular token standards have been implementing while also conforming to the ilrta standard.

- [ERC20](https://github.com/kyscott18/ilrta/blob/main/src/examples/ERC20.sol)

As well as some more examples, such as:

- [FungibleToken](https://github.com/kyscott18/ilrta/blob/main/src/examples/FungibleToken.sol)

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

## Acknowledgements

- **Uniswap's permit2** for their signature verification implementation and pushing the boundaries of what I thought was possible
- **Uniswap's v3-core** for showing the need of an extensible standard for creating small token types
- **Noah Zinsmeister and Sara Reynolds** for personally taking the time to talk through some of these ideas
- **Solmate** for an incredibly clean eip2612 and erc20 implementation to base off of
- [**This Twitter thread**](https://twitter.com/pcaversaccio/status/1645084293989822466?s=20) for discussion on the shortcomings of current standards
