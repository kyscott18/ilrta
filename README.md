# ilrta [![GitHub Actions][gha-badge]][gha] [![License: MIT][license-badge]][license]

[gha]: https://github.com/kyscott18/ilrta/actions
[gha-badge]: https://github.com/kyscott18/ilrta/actions/workflows/main.yml/badge.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

**ilrta** is a framework for creating tokens for exotic use cases. The goal is to allow for custom standards to be created yet still retain composability. This currently consists of:

- `ILRTA`: Token standard for token standards. Easily tokenize any data but share common infrastructure and maintain composability.
- `Permit3`: Next version of permit2 with multiple token support.

## `ILRTA`

### Abstract

This protocol is adapted around two main ideas: token standards at their core just represent ownership over arbitrary data, and the approve flow used by almost all token standards is suboptimal. Instead, a higher level manager such as permit3 should be used because of its extensive features while still being permissionlessly upgradeable.

Because of the lack of support for type generics in Solidity, the implementation is lacking. `ILRTATemplate.sol` contains a more complete picture of what is needed to implement ilrta.

### Features

- Easiest way to create a token type for one-off contracts
- Consistent events across all inheriting contracts
- Out of the box support for a higher level signature transfer contact, `permit3`
- Full test suite running with Foundry

## `Permit3`

### Features

- Supports more than just ERC20, including ERC721, ERC1155, ILRTA
- Supports signatures for undeployed smart contract wallets (EIP 6492)

## Potential Improvements

- Don't allow for function selector to be passed in because it may be dangerous.
- Function to validate signature without passing in any transfer data.
- Write a script that generates an ilrta implementation contract, complete with function selector mining
- Use fallback instead of mining function selectors

## Acknowledgements

- **Uniswap's permit2**
- **Uniswap's v3-core**
- **Noah Zinsmeister and Sara Reynolds**
- **Solmate**
- [**This Twitter thread**](https://twitter.com/pcaversaccio/status/1645084293989822466?s=20)
