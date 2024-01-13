// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";

contract DecimalsTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();
    }

    function test_Decimals() external {
        assertEq(mockft.decimals(), 18);
    }
}
