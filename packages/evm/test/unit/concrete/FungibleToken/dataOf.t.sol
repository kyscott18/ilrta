// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

contract DataOfTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();
    }

    function test_DataOf_Selector() external {
        assertEq(ILRTAFungibleToken.dataOf_cGJnTo.selector, bytes4(keccak256("dataOf()")));
    }
}
