// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

contract AllowanceOfTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();
    }
}
