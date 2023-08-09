// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Test} from "forge-std/Test.sol";

import {MockFungibleToken} from "../../../mocks/MockFungibleToken.sol";
import {ILRTAFungibleToken} from "src/examples/FungibleToken.sol";

contract ValidRequestTest is Test {
    MockFungibleToken private mockft;

    function setUp() external {
        mockft = new MockFungibleToken();
    }

    function test_Approve_Selector() external {
        assertEq(ILRTAFungibleToken.approve_cMebqQ.selector, bytes4(keccak256("approve()")));
    }
}
