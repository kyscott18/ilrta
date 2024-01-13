# ilrta smart contracts [![Foundry][foundry-badge]][foundry]

[foundry]: https://getfoundry.sh/
[foundry-badge]: https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg

## Example Implementations

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
pnpm install
```

### Build

```sh
forge build
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
