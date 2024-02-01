// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ILRTASemiFungibleToken} from "src/examples/SemiFungibleToken.sol";

contract MockSemiFungibleToken is ILRTASemiFungibleToken {
    constructor() ILRTASemiFungibleToken("Test SFT", "TEST") {}

    function mint(address to, uint256 id, uint256 amount) external {
        _mint(to, id, amount);
    }

    function burn(address from, uint256 id, uint256 amount) external {
        _burn(from, id, amount);
    }
}
