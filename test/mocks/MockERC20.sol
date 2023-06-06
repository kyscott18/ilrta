// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "src/examples/ERC20.sol";

contract MockERC20 is ERC20("Test ERC20", "TEST", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        _burn(from, amount);
    }
}
