// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {FungibleToken} from "src/examples/FungibleToken.sol";

contract MockFungibleToken is FungibleToken("Test FT", "TEST", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
