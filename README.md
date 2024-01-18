# ilrta [![GitHub Actions][gha-badge]][gha] [![License: MIT][license-badge]][license]

[gha]: https://github.com/kyscott18/ilrta/actions
[gha-badge]: https://github.com/kyscott18/ilrta/actions/workflows/main.yml/badge.svg
[license]: https://opensource.org/licenses/MIT
[license-badge]: https://img.shields.io/badge/License-MIT-blue.svg

Composable token standard and transfer utilities. **ilrta** standardizes event logs, function selector, and transfer + approve flow. **Permit3** implements `transferBySignature` for all current and future token standards.

## Potential Improvements

- Permit3: compute function selector rather than pass it in.
- Permit3: Function to validate signature without passing in any transfer data.

## Acknowledgements

- **Uniswap's permit2**
- **Uniswap's v3-core**
- **Noah Zinsmeister and Sara Reynolds**
- **Solmate**
- [**This Twitter thread**](https://twitter.com/pcaversaccio/status/1645084293989822466?s=20)
