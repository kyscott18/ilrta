// SPDX-License-Identifier: GPL-3.0-only
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "./mocks/MockERC20.sol";

contract ERC20Test is Test {
    MockERC20 private erc20;

    function setUp() public {
        erc20 = new MockERC20();
    }

    function testMetadata() public {
        assertEq(erc20.name(), "Test ERC20");
        assertEq(erc20.symbol(), "TEST");
        assertEq(erc20.decimals(), 18);
    }

    function testMint() public {
        erc20.mint(address(0xC0FFEE), 1e18);

        assertEq(erc20.totalSupply(), 1e18);
        assertEq(erc20.balanceOf(address(0xC0FFEE)), 1e18);
    }

    function testBurn() public {
        erc20.mint(address(0xC0FFEE), 1e18);
        erc20.burn(address(0xC0FFEE), 0.9e18);

        assertEq(erc20.totalSupply(), 1e18 - 0.9e18);
        assertEq(erc20.balanceOf(address(0xC0FFEE)), 0.1e18);
    }
}
